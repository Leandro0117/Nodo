// services/accountService.js
import { prisma } from "../database/prisma.js";
import redis from "../database/redisClient.js";
import { deleteFirebaseUser } from "../utils/firebase.js";
import { deleteFolder } from "./storageService.js";

// Los valores neutros se derivan del id: dni, email y phone son únicos y
// obligatorios, así que cada cuenta desactivada necesita los suyos. El
// dominio .invalid está reservado y nunca puede pertenecer a nadie.
function neutralData(userId) {
  return {
    firstName: "Usuario",
    lastName: "desactivado",
    secondLastName: null,
    dni: `deactivated_${userId}`,
    email: `deactivated_${userId}@nodo.invalid`,
    phone: `deactivated_${userId}`,
    birthDate: new Date(Date.UTC(1900, 0, 1)),
    // No es un hash de bcrypt, así que ninguna contraseña coincide.
    passwordHash: "",
    profilePhoto: null,
    location: null,
    fcmToken: null,
    verified: false,
  };
}

// Un trabajo en curso solo se cierra cuando el cliente lo confirma, y el pago
// dependerá de eso. Si una de las dos partes se va, el trabajo queda trabado
// para siempre, así que primero hay que finalizarlo.
export class ActiveJobsError extends Error {
  constructor() {
    super("The user has jobs in progress.");
    this.name = "ActiveJobsError";
  }
}

/**
 * Desactiva la cuenta y borra sus datos personales en una sola transacción:
 * o queda bloqueada y anónima, o no cambia nada. La fila se conserva porque
 * su historial está ligado a publicaciones, postulaciones y reseñas de otros.
 *
 * Los archivos en Storage y el usuario de Firebase no pueden entrar en la
 * transacción; se borran después, con reintentos (ver cleanUpDeactivatedAccount).
 *
 * Lanza ActiveJobsError si tiene un trabajo en curso, como cliente o como
 * trabajador. Se revisa dentro de una transacción Serializable: si al mismo
 * tiempo se acepta una de sus postulaciones, Postgres aborta una de las dos
 * en vez de dejar pasar una cuenta desactivada con un trabajo en curso.
 */
export async function deactivateAccount(userId) {
  const { firebaseUid, posts } = await prisma.$transaction(async (tx) => {
    const activeJobs = await tx.service.count({
      where: {
        status: "in_progress",
        application: { OR: [{ workerId: userId }, { post: { clientId: userId } }] },
      },
    });
    if (activeJobs > 0) throw new ActiveJobsError();

    const user = await tx.appUser.update({
      where: { id: userId },
      data: { ...neutralData(userId), status: "deactivated" },
      select: { firebaseUid: true, posts: { select: { id: true } } },
    });

    // Sin rubros deja de recibir avisos de nuevas publicaciones.
    await tx.workerCategory.deleteMany({ where: { workerId: userId } });
    await tx.worker.updateMany({ where: { userId }, data: { description: null } });

    // Las postulaciones abiertas se retiran para que los clientes no esperen
    // respuesta de alguien que ya no está. Las resueltas quedan como historial.
    await tx.application.updateMany({
      where: { workerId: userId, status: "pending" },
      data: { status: "withdrawn" },
    });

    await tx.bankAccount.updateMany({
      where: { userId },
      data: { accountNumber: "deactivated" },
    });

    return user;
  }, { isolationLevel: "Serializable" });

  return { firebaseUid, postIds: posts.map((p) => p.id) };
}

const RETRY_DELAYS_MS = [0, 2_000, 10_000];

async function withRetries(label, fn) {
  for (const [attempt, delay] of RETRY_DELAYS_MS.entries()) {
    if (delay) await new Promise((resolve) => setTimeout(resolve, delay));
    try {
      await fn();
      return true;
    } catch (error) {
      console.error(`[desactivar] ${label} · intento ${attempt + 1}/${RETRY_DELAYS_MS.length} falló:`, error.message);
    }
  }
  return false;
}

/**
 * Borra lo que la cuenta dejó fuera de la base: fotos de perfil y de
 * publicaciones, el usuario de Firebase (que guarda el celular) y las
 * notificaciones en Redis. La cuenta ya está bloqueada, así que un fallo aquí
 * no reabre el acceso. Si Firebase no se pudo borrar, firebase_uid se conserva
 * para reintentarlo más adelante; si se borró, se limpia.
 */
export async function cleanUpDeactivatedAccount(userId, { firebaseUid, postIds }) {
  // La app sube la foto de perfil como "perfiles/<id>_<archivo>".
  const prefixes = [`perfiles/${userId.toLowerCase()}_`, ...postIds.map((id) => `publicaciones/${id}/`)];
  for (const prefix of prefixes) {
    await withRetries(`Storage ${prefix}`, () => deleteFolder(prefix));
  }

  await withRetries("Redis", () => redis.del(`notifications:${userId}`));

  if (firebaseUid) {
    const deleted = await withRetries("Firebase", () => deleteFirebaseUser(firebaseUid));
    if (deleted) {
      await prisma.appUser.update({ where: { id: userId }, data: { firebaseUid: null } });
    } else {
      console.error(`[desactivar] El usuario ${userId} conserva firebase_uid para reintentar el borrado.`);
    }
  }
}
