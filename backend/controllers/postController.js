import { prisma } from "../database/prisma.js";
import { notifyWorkersByCategories } from "../services/notificationService.js";
import { deleteFolder } from "../services/storageService.js";

const postInclude = { photos: true, categories: { include: { specificCategory: true } } };

function serializePost(post) {
  if (!post) return post;
  return {
    ...post,
    photos: (post.photos ?? [])
      .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))
      .map((p) => p.url),
  };
}

export const getPosts = async (req, res) => {
  try {
    const posts = await prisma.post.findMany({ include: postInclude });
    res.json(posts.map(serializePost));
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

export const getPostsForWorker = async (req, res) => {
  try {
    const { workerId } = req.params;

    const workerCategories = await prisma.workerCategory.findMany({
      where: { workerId },
      select: { generalCategoryId: true },
    });

    if (workerCategories.length === 0) return res.json([]);

    const generalCategoryIds = workerCategories.map((wc) => wc.generalCategoryId);

    const hierarchies = await prisma.categoryHierarchy.findMany({
      where: { generalCategoryId: { in: generalCategoryIds } },
      select: { specificCategoryId: true },
    });

    const specificCategoryIds = [...new Set(hierarchies.map((h) => h.specificCategoryId))];

    if (specificCategoryIds.length === 0) return res.json([]);

    const posts = await prisma.post.findMany({
      where: {
        categories: {
          some: { specificCategoryId: { in: specificCategoryIds } },
        },
      },
      include: postInclude,
    });

    res.json(posts.map(serializePost));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

export const getPost = async (req, res) => {
  try {
    const post = await prisma.post.findUnique({
      where: { id: req.params.id },
      include: postInclude,
    });

    if (!post) {
      return res.status(404).json({ message: "No records found" });
    }

    res.json(serializePost(post));
  } catch (error) {
    if (!res.headersSent) {
      res.status(500).json({ message: error.message });
    }
  }
};

export const getPostsByUserId = async (req, res) => {
  try {
    const posts = await prisma.post.findMany({
      where: { clientId: req.params.id },
      include: postInclude,
    });

    if (posts.length === 0) {
      return res.status(200).json({ message: "No records found" });
    }

    res.json(posts.map(serializePost));
  } catch (error) {
    if (!res.headersSent) {
      res.status(500).json({ message: error.message });
    }
  }
};

export const createPost = async (req, res) => {
  try {
    const { clientId, title, specificCategoryIds, location, budget, deadline, description } = req.body;

    if (
      !clientId ||
      !specificCategoryIds ||
      !Array.isArray(specificCategoryIds) ||
      specificCategoryIds.length === 0 ||
      !title ||
      !description ||
      !location ||
      !budget ||
      !deadline
    ) {
      return res.status(400).json({ message: "Missing required fields or invalid categories." });
    }

    const client = await prisma.appUser.findUnique({ where: { id: clientId } });
    if (!client) {
      return res.status(404).json({ message: "Client does not exist." });
    }

    const categoryIds = specificCategoryIds.map(Number);

    const matchingCategories = await prisma.specificCategory.findMany({
      where: { id: { in: categoryIds } },
    });
    if (matchingCategories.length !== categoryIds.length) {
      return res.status(404).json({ message: "One or more categories do not exist." });
    }

    const post = await prisma.post.create({
      data: {
        clientId,
        title,
        description,
        location,
        budget: Number(budget),
        deadline: new Date(deadline),
        status: "pending",
        categories: {
          create: categoryIds.map((specificCategoryId) => ({ specificCategoryId })),
        },
      },
      include: postInclude,
    });

    res.status(201).json({
      ...serializePost(post),
      message: "Post created successfully",
    });

    await notifyWorkersByCategories(post.id, clientId, categoryIds);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

// Max 10 photos per post, validated here since it can't be expressed as a
// database constraint.
export const addPostPhotos = async (req, res) => {
  try {
    const postId = req.params.id;
    const { urls } = req.body;

    if (!Array.isArray(urls) || urls.length === 0) {
      return res.status(400).json({ message: "An 'urls' array with at least one element is required." });
    }

    const existingCount = await prisma.postPhoto.count({ where: { postId } });
    if (existingCount + urls.length > 10) {
      return res.status(400).json({
        message: `This post already has ${existingCount} photos; it cannot exceed the maximum of 10.`,
      });
    }

    const photos = await prisma.postPhoto.createMany({
      data: urls.map((url, index) => ({
        postId,
        url,
        sortOrder: existingCount + index,
      })),
    });

    res.status(201).json({ message: "Photos added successfully", count: photos.count });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

export const updatePost = async (req, res) => {
  try {
    const postId = req.params.id;
    const data = { ...req.body };

    // Photos go to their own table, not a column on post.
    if (data.photos) {
      const urls = Array.isArray(data.photos) ? data.photos : [data.photos];
      delete data.photos;
      const existingCount = await prisma.postPhoto.count({ where: { postId } });
      await prisma.postPhoto.createMany({
        data: urls.map((url, index) => ({ postId, url, sortOrder: existingCount + index })),
      });
    }

    // Las categorías son una relación, no una columna escalar: se reemplaza el conjunto.
    if (data.specificCategoryIds) {
      const categoryIds = data.specificCategoryIds.map(Number);
      delete data.specificCategoryIds;

      const matchingCategories = await prisma.specificCategory.findMany({
        where: { id: { in: categoryIds } },
      });
      if (matchingCategories.length !== categoryIds.length) {
        return res.status(404).json({ message: "One or more categories do not exist." });
      }

      data.categories = {
        deleteMany: {},
        create: categoryIds.map((specificCategoryId) => ({ specificCategoryId })),
      };
    }

    if (data.deadline) {
      data.deadline = new Date(data.deadline);
    }

    if (Object.keys(data).length > 0) {
      await prisma.post.update({ where: { id: postId }, data });
    }

    res.json({ message: "Data updated successfully" });
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "Record not found" });
    }
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

export const deletePost = async (req, res) => {
  try {
    const postId = req.params.id;
    await prisma.post.delete({ where: { id: postId } });

    try {
      await deleteFolder(`publicaciones/${postId}/`);
    } catch (storageError) {
      console.error(`Error deleting photos for post ${postId}:`, storageError);
    }

    res.json({ message: "Record deleted successfully" });
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "Record not found" });
    }
    if (error.code === "P2003") {
      return res.status(409).json({
        message: "Cannot delete: this post has applications or other related records.",
      });
    }
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};
