// notificationService.js
import { v4 as uuidv4 } from "uuid";
import redis from "../database/redisClient.js";
import { prisma } from "../database/prisma.js";
import { sendNotificationToUser } from "../utils/firebase.js";

export async function saveNotification(userId, type, title, message, data) {
  if (!userId || !title || !message || !type) {
    throw new Error("Missing required fields");
  }
  const notification = {
    id: uuidv4(),
    type,
    title,
    message,
    data,
    date: new Date().toISOString(),
  };

  try {
    await redis.lPush(`notifications:${userId}`, JSON.stringify(notification));
  } catch (err) {
    console.log("Could not save notification to Redis, continuing without it:", err.message);
  }

  const user = await prisma.appUser.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });

  if (user?.fcmToken) {
    const { invalidToken } = await sendNotificationToUser(user.fcmToken, title, message, data);

    // El token murió (app desinstalada o rotado). Se borra acá porque este es
    // el punto que conoce el userId; si no, queda envenenando cada envío futuro.
    if (invalidToken) {
      await prisma.appUser.update({ where: { id: userId }, data: { fcmToken: null } });
      console.log(`FCM token no longer valid for user ${userId}; cleared.`);
    }
  }

  return notification;
}

// A post has specific categories. A worker has general categories. The
// match is: does any specific category of the post hang from any general
// category the worker has? One match is enough, full coverage isn't required.
export const notifyWorkersByCategories = async (postId, clientId, specificCategoryIds) => {
  try {
    const generalCategoryLinks = await prisma.categoryHierarchy.findMany({
      where: { specificCategoryId: { in: specificCategoryIds } },
      select: { generalCategoryId: true },
    });
    const generalCategoryIds = [...new Set(generalCategoryLinks.map((l) => l.generalCategoryId))];

    if (generalCategoryIds.length === 0) {
      console.log("None of the specific categories have general categories linked; no one to notify.");
      return;
    }

    const matchingWorkers = await prisma.workerCategory.findMany({
      where: { generalCategoryId: { in: generalCategoryIds } },
      select: { workerId: true },
    });

    const workerIds = [...new Set(matchingWorkers.map((w) => w.workerId))].filter(
      (workerId) => workerId !== clientId
    );

    console.log("Workers to notify:", workerIds);

    for (const workerId of workerIds) {
      await saveNotification(
        workerId,
        "offer",
        "New job opportunity",
        "A new job opportunity is available in your category!",
        { postId: postId.toString(), workerId: workerId.toString() }
      );
      console.log(`Notification sent to worker ${workerId}`);
    }
  } catch (notificationError) {
    console.error("Error sending notifications:", notificationError);
  }
};
