import { prisma } from "../database/prisma.js";

/**
 * Rechaza con 403 las escrituras a nombre de una cuenta que no está activa.
 * Mientras no exista el middleware de autenticación, un dispositivo con la
 * sesión abierta de una cuenta desactivada podría seguir publicando o
 * reescribiendo sus datos; esto lo impide en las rutas que lo usan.
 *
 * getUserId saca el id de la petición. Si no viene o el usuario no existe,
 * deja pasar la petición para que el controlador responda como siempre.
 */
export const requireActiveUser = (getUserId) => async (req, res, next) => {
  const userId = getUserId(req);
  if (!userId) return next();

  try {
    const user = await prisma.appUser.findUnique({
      where: { id: String(userId) },
      select: { status: true },
    });
    if (user && user.status !== "active") {
      return res.status(403).json({ message: "Account is not active." });
    }
    next();
  } catch (error) {
    console.error("Error checking user status:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
