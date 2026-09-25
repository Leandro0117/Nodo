import { prisma } from "../database/prisma.js";

// POST /api/createRating
// body: { serviceId, raterId, ratedId, score, comment? }
export const createRating = async (req, res) => {
  try {
    const { serviceId, raterId, ratedId, score, comment } = req.body;

    if (!serviceId || !raterId || !ratedId || score == null) {
      return res.status(400).json({ message: "Missing required fields." });
    }

    if (!Number.isInteger(score) || score < 1 || score > 5) {
      return res.status(400).json({ message: "Score must be an integer between 1 and 5." });
    }

    const service = await prisma.service.findUnique({ where: { id: serviceId } });
    if (!service) {
      return res.status(404).json({ message: "Service not found." });
    }

    if (service.status !== "completed") {
      return res.status(400).json({ message: "Cannot rate a service that is not completed." });
    }

    const review = await prisma.review.create({
      data: {
        serviceId,
        reviewerId: raterId,
        reviewedId: ratedId,
        rating: score,
        comment: comment ?? null,
      },
    });

    res.status(201).json({ ...review, message: "Rating submitted successfully." });
  } catch (error) {
    if (error.code === "P2002") {
      return res.status(409).json({ message: "You already rated this service." });
    }
    console.error(error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

// GET /api/getUserRatings/:userId
// Devuelve { asWorker: { avg, count }, asClient: { avg, count } }
export const getUserRatings = async (req, res) => {
  try {
    const { userId } = req.params;

    const [workerReviews, clientReviews] = await Promise.all([
      // Calificaciones recibidas actuando como TRABAJADOR
      prisma.review.findMany({
        where: {
          reviewedId: userId,
          service: { application: { workerId: userId } },
        },
        select: { rating: true },
      }),
      // Calificaciones recibidas actuando como CLIENTE
      prisma.review.findMany({
        where: {
          reviewedId: userId,
          service: { application: { post: { clientId: userId } } },
        },
        select: { rating: true },
      }),
    ]);

    const avg = (reviews) =>
      reviews.length === 0
        ? null
        : reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

    res.json({
      asWorker: { avg: avg(workerReviews), count: workerReviews.length },
      asClient: { avg: avg(clientReviews), count: clientReviews.length },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

// GET /api/getRatingByServiceAndUser/:serviceId/:userId
export const getRatingByServiceAndUser = async (req, res) => {
  try {
    const { serviceId, userId } = req.params;

    const review = await prisma.review.findUnique({
      where: {
        reviewerId_serviceId: {
          reviewerId: userId,
          serviceId,
        },
      },
    });

    if (!review) {
      return res.status(404).json({ message: "Rating not found." });
    }

    res.json(review);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};
