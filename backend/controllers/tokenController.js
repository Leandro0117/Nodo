import { prisma } from "../database/prisma.js";
import { sendNotificationToUser } from "../utils/firebase.js";

export const saveToken = async (req, res) => {
  const { userId, token } = req.body;

  if (!userId || !token) {
    return res.status(400).json({ message: "Missing required data (userId or token)." });
  }

  try {
    const user = await prisma.appUser.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    if (user.fcmToken === token) {
      return res.status(200).json({ message: "Token was already up to date. No changes made." });
    }

    await prisma.appUser.update({
      where: { id: userId },
      data: { fcmToken: token },
    });

    const { invalidToken } = await sendNotificationToUser(
      token,
      "Token registered",
      "The FCM token was saved successfully",
      { type: "system" }
    );

    // FCM rechazó el token recién guardado, así que no sirve: se revierte para
    // no dejarlo en la base y se avisa al cliente, que de otro modo lo cachearía.
    if (invalidToken) {
      await prisma.appUser.update({ where: { id: userId }, data: { fcmToken: null } });
      return res.status(400).json({ message: "The FCM token was rejected by Firebase." });
    }

    return res.status(200).json({ message: "Token updated successfully." });
  } catch (error) {
    console.error("Error saving token:", error);
    return res.status(500).json({ message: "Internal server error." });
  }
};

export const deleteToken = async (req, res) => {
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ message: "userId is required." });
  }

  try {
    const user = await prisma.appUser.findUnique({ where: { id: userId } });
    if (!user?.fcmToken) {
      return res.status(200).json({ message: "User had no token registered." });
    }

    await prisma.appUser.update({
      where: { id: userId },
      data: { fcmToken: null },
    });

    return res.status(200).json({ message: "Token deleted successfully." });
  } catch (error) {
    console.error("Error deleting token:", error);
    return res.status(500).json({ message: "Internal server error." });
  }
};
