import bcrypt from "bcryptjs";
import { prisma } from "../database/prisma.js";
import { verifyPhoneIdToken } from "../utils/firebase.js";
import { logRegistro, mask } from "../utils/debugLog.js";
import { deactivateAccount, cleanUpDeactivatedAccount, ActiveJobsError } from "../services/accountService.js";

// Solo para desarrollo local (por ejemplo, probar desde Bruno sin SMS).
// Las cuentas creadas así quedan con verified = false y firebase_uid = null.
const SKIP_PHONE_VERIFICATION = process.env.DEV_SKIP_PHONE_VERIFICATION === "true";
if (SKIP_PHONE_VERIFICATION) {
  console.warn(
    "⚠️  DEV_SKIP_PHONE_VERIFICATION=true: se pueden crear cuentas sin verificar " +
    "el celular. Nunca actives esta variable en producción."
  );
}

// Normaliza un celular colombiano a E.164 (+573001234567). Acepta
// "3001234567", "300 123 4567", "573001234567" o "+573001234567".
// Devuelve null si no es un celular válido (10 dígitos que empiezan por 3).
function toColombianE164(phone) {
  const digits = String(phone ?? "").replace(/\D/g, "");
  const local = digits.length === 12 && digits.startsWith("57") ? digits.slice(2) : digits;
  return /^3\d{9}$/.test(local) ? `+57${local}` : null;
}

const userInclude = {
  worker: { include: { workerCategories: { include: { generalCategory: true } } } },
};

// The frontend's date picker sends dates as "dd/MM/yyyy", which JS's Date
// constructor cannot parse reliably (it expects ISO format). Accepts both
// "dd/MM/yyyy" and ISO strings.
function parseBirthDate(value) {
  const ddmmyyyy = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(value);
  if (ddmmyyyy) {
    const [, day, month, year] = ddmmyyyy;
    return new Date(Number(year), Number(month) - 1, Number(day));
  }
  return new Date(value);
}

function omitPassword(user) {
  if (!user) return user;
  const { passwordHash, ...rest } = user;
  return rest;
}

export const getUsers = async (req, res) => {
  try {
    const users = await prisma.appUser.findMany({ include: userInclude });
    res.json(users.map(omitPassword));
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

export const getUser = async (req, res) => {
  try {
    const user = await prisma.appUser.findUnique({
      where: { id: req.params.id },
      include: userInclude,
    });

    if (!user) {
      return res.status(404).json({ message: "No records found" });
    }

    res.json(omitPassword(user));
  } catch (error) {
    if (!res.headersSent) {
      res.status(500).json({ message: error.message });
    }
  }
};

// id is no longer sent by the client: Prisma generates it automatically.
// If isWorker is true, a Worker profile is created alongside the user.
export const createUser = async (req, res) => {
  try {
    const data = req.body;
    logRegistro(
      `createUser · campos: ${Object.keys(data).filter((k) => k !== "password" && k !== "phoneIdToken").join(", ")} · ` +
      `phoneIdToken: ${data.phoneIdToken ? `sí (${data.phoneIdToken.length} caracteres)` : "NO"}`
    );

    const requiredFields = [
      "firstName",
      "lastName",
      "dni",
      "email",
      "phone",
      "birthDate",
      "password",
    ];
    const missing = requiredFields.filter((field) => !data[field]);
    if (missing.length > 0) {
      logRegistro(`✗ Faltan campos: ${missing.join(", ")}`);
      return res.status(400).json({
        message: `Missing required fields: ${missing.join(", ")}`,
      });
    }

    const birthDate = parseBirthDate(data.birthDate);
    if (isNaN(birthDate.getTime())) {
      return res.status(400).json({ message: "Invalid birthDate." });
    }

    // El celular debe venir confirmado por Firebase con el código de 6 dígitos.
    const phoneE164 = toColombianE164(data.phone);
    logRegistro(`Celular recibido "${mask(data.phone)}" → normalizado ${mask(phoneE164)}`);
    if (!phoneE164) {
      logRegistro("✗ No es un celular colombiano válido (10 dígitos que empiezan por 3)");
      return res.status(400).json({ message: "Invalid phone number." });
    }

    let phoneVerified = false;
    let firebaseUid = null;
    if (data.phoneIdToken) {
      try {
        const { phone: verifiedPhone, uid } = await verifyPhoneIdToken(data.phoneIdToken);
        if (verifiedPhone !== phoneE164) {
          logRegistro(`✗ No coinciden: Firebase verificó ${mask(verifiedPhone)} y el formulario trae ${mask(phoneE164)}`);
          return res.status(401).json({
            message: "The verified phone does not match the submitted phone.",
          });
        }
        phoneVerified = true;
        firebaseUid = uid;
        logRegistro("✓ El celular del token coincide con el del formulario");
      } catch (error) {
        logRegistro(`✗ Token rechazado → 401 (${error.code ?? error.message})`);
        return res.status(401).json({ message: "Phone verification failed or expired." });
      }
    } else if (!SKIP_PHONE_VERIFICATION) {
      logRegistro("✗ Llegó sin phoneIdToken y DEV_SKIP_PHONE_VERIFICATION no está activa → 400");
      return res.status(400).json({ message: "Missing phoneIdToken." });
    } else {
      console.warn(`⚠️  Cuenta ${data.email} creada sin verificar el celular (modo desarrollo).`);
    }

    const passwordHash = await bcrypt.hash(data.password, 10);

    const user = await prisma.appUser.create({
      data: {
        firstName: data.firstName,
        lastName: data.lastName,
        secondLastName: data.secondLastName ?? null,
        dni: data.dni,
        email: data.email,
        // Se guarda en formato local (10 dígitos) para que el login por teléfono siga igual.
        phone: phoneE164.slice(3),
        birthDate,
        passwordHash,
        profilePhoto: data.profilePhoto ?? null,
        location: data.location ?? null,
        // Por ahora "verified" significa "celular confirmado por SMS".
        verified: phoneVerified,
        // Para poder borrar ese usuario de Firebase si la cuenta se desactiva.
        firebaseUid,
      },
    });

    logRegistro(`✓ Usuario creado ${user.id} · verified=${phoneVerified}`);

    let worker = null;
    if (data.isWorker) {
      worker = await prisma.worker.create({
        data: {
          userId: user.id,
          description: data.description ?? null,
        },
      });
    }

    res.status(200).json({
      message: "User registered successfully",
      user: { ...omitPassword(user), worker: worker ? { ...worker, workerCategories: [] } : null },
    });
  } catch (error) {
    console.error("Error creating user:", error);
    if (error.code === "P2002") {
      logRegistro(`✗ Duplicado en: ${error.meta?.target ?? "campo desconocido"} → 409`);
      return res.status(409).json({
        message: "A user with that DNI, email, or phone already exists.",
      });
    }
    res.status(500).json({ message: "Error registering user", error: error.message });
  }
};

// Se llama antes de enviar el SMS, para no gastar un mensaje en un registro
// que después fallaría por cédula, correo o teléfono repetidos.
export const checkAvailability = async (req, res) => {
  const { email, phone, dni } = req.body ?? {};
  const phoneE164 = toColombianE164(phone);
  logRegistro(`checkAvailability · correo ${email} · cédula ${dni} · celular "${mask(phone)}" → ${mask(phoneE164)}`);

  if (!email || !dni || !phoneE164) {
    logRegistro("✗ Datos incompletos o celular inválido → 400");
    return res.status(400).json({
      message: "email, dni and a valid Colombian mobile phone are required.",
    });
  }

  try {
    const existing = await prisma.appUser.findFirst({
      where: { OR: [{ email }, { dni }, { phone: phoneE164.slice(3) }] },
      select: { id: true, email: true, dni: true, phone: true },
    });

    if (existing) {
      // Solo en el log: la respuesta no dice qué dato está ocupado, a propósito.
      const taken = [
        existing.email === email && "correo",
        existing.dni === dni && "cédula",
        existing.phone === phoneE164.slice(3) && "celular",
      ].filter(Boolean);
      logRegistro(`✗ Ya registrado (${taken.join(", ")}) en el usuario ${existing.id} → 409`);
      return res.status(409).json({
        message: "A user with that DNI, email, or phone already exists.",
      });
    }

    logRegistro("✓ Datos libres → 200");
    res.status(200).json({ available: true });
  } catch (error) {
    console.error("Error checking availability:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const login = async (req, res) => {
  const { identifier, password } = req.body; // phone or email

  try {
    const user = await prisma.appUser.findFirst({
      where: { OR: [{ phone: identifier }, { email: identifier }] },
      include: userInclude,
    });

    if (!user) {
      return res.status(401).json({ messageFail: "Invalid credentials" });
    }

    const passwordMatches = await bcrypt.compare(password, user.passwordHash);
    if (!passwordMatches) {
      return res.status(401).json({ messageFail: "Invalid credentials" });
    }

    // Una cuenta desactivada ya no coincide con ningún correo ni celular, así
    // que en la práctica esto solo lo alcanza una cuenta en revisión.
    if (user.status !== "active") {
      return res.status(403).json({ messageFail: "Account is not active", status: user.status });
    }

    return res.status(200).json({
      messageSuccess: "Login successful",
      user: omitPassword(user),
    });
  } catch (error) {
    console.error("Error en login:", error);
    return res.status(500).json({ messageFail: "Server error", error: error.message });
  }
};

export const updateUser = async (req, res) => {
  try {
    const userId = req.params.id;
    const data = { ...req.body };

    if (data.password) {
      data.passwordHash = await bcrypt.hash(data.password, 10);
      delete data.password;
    }
    if (data.birthDate) {
      data.birthDate = parseBirthDate(data.birthDate);
    }

    // Estos dos viven en Worker/WorkerCategory, no en AppUser, así que no
    // pueden pasar por prisma.appUser.update junto con el resto de `data`.
    const description = data.description;
    delete data.description;
    const generalCategoryIds = data.generalCategoryIds;
    delete data.generalCategoryIds;

    if (Object.keys(data).length > 0) {
      await prisma.appUser.update({ where: { id: userId }, data });
    }

    if (description !== undefined) {
      await prisma.worker.update({ where: { userId }, data: { description } });
    }

    if (Array.isArray(generalCategoryIds)) {
      const categoryIds = generalCategoryIds.map(Number);
      await prisma.workerCategory.deleteMany({ where: { workerId: userId } });
      await prisma.workerCategory.createMany({
        data: categoryIds.map((generalCategoryId) => ({ workerId: userId, generalCategoryId })),
        skipDuplicates: true,
      });
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

// Convierte a un cliente existente en trabajador: crea su fila en Worker
// (si todavía no la tiene) y le asigna los rubros elegidos. Es idempotente,
// así que también sirve si alguien reintenta tras un error de red.
export const activateWorker = async (req, res) => {
  try {
    const userId = req.params.id;
    const { description, generalCategoryIds, location } = req.body;

    if (!description || !Array.isArray(generalCategoryIds) || generalCategoryIds.length === 0) {
      return res.status(400).json({
        message: "'description' y al menos un rubro en 'generalCategoryIds' son obligatorios.",
      });
    }

    const user = await prisma.appUser.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ message: "El usuario no existe." });
    }

    const categoryIds = generalCategoryIds.map(Number);
    const matchingCategories = await prisma.generalCategory.findMany({
      where: { id: { in: categoryIds } },
    });
    if (matchingCategories.length !== categoryIds.length) {
      return res.status(404).json({ message: "Uno o más rubros no existen." });
    }

    await prisma.worker.upsert({
      where: { userId },
      create: { userId, description },
      update: { description },
    });

    if (location) {
      await prisma.appUser.update({ where: { id: userId }, data: { location } });
    }

    await prisma.workerCategory.deleteMany({ where: { workerId: userId } });
    await prisma.workerCategory.createMany({
      data: categoryIds.map((generalCategoryId) => ({ workerId: userId, generalCategoryId })),
      skipDuplicates: true,
    });

    res.json({ message: "Perfil de trabajador activado correctamente" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

export const resetPassword = async (req, res) => {
  const { email, dni, newPassword } = req.body;

  if (!email || !dni || !newPassword) {
    return res.status(400).json({ message: "Email, cédula y nueva contraseña son requeridos." });
  }
  if (newPassword.length < 6) {
    return res.status(400).json({ message: "La contraseña debe tener al menos 6 caracteres." });
  }

  try {
    const user = await prisma.appUser.findFirst({ where: { email, dni } });
    if (!user) {
      return res.status(404).json({ message: "No se encontró una cuenta con ese correo y cédula." });
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await prisma.appUser.update({ where: { id: user.id }, data: { passwordHash } });

    res.json({ message: "Contraseña actualizada correctamente." });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

export const deleteUser = async (req, res) => {
  try {
    await prisma.appUser.delete({ where: { id: req.params.id } });
    res.json({ message: "Record deleted successfully" });
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "Record not found" });
    }
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

// Irreversible: bloquea la cuenta y reemplaza sus datos personales por valores
// neutros. Pide la contraseña porque todavía no hay middleware de
// autenticación: sin ella, cualquiera que conozca el id podría desactivarla.
export const deactivateUser = async (req, res) => {
  const userId = req.params.id;
  const { password } = req.body ?? {};

  if (!password) {
    return res.status(400).json({ message: "password is required." });
  }

  try {
    const user = await prisma.appUser.findUnique({
      where: { id: userId },
      select: { passwordHash: true, status: true },
    });
    if (!user || user.status === "deactivated") {
      return res.status(404).json({ message: "User not found." });
    }

    const passwordMatches = await bcrypt.compare(password, user.passwordHash);
    if (!passwordMatches) {
      return res.status(401).json({ message: "Invalid password." });
    }

    const leftovers = await deactivateAccount(userId);
    console.log(`[desactivar] Cuenta ${userId} desactivada.`);

    // La cuenta ya quedó bloqueada: el resto se limpia sin hacer esperar a la app.
    cleanUpDeactivatedAccount(userId, leftovers).catch((error) =>
      console.error(`[desactivar] Limpieza de ${userId} interrumpida:`, error)
    );

    res.json({ message: "Account deactivated." });
  } catch (error) {
    if (error instanceof ActiveJobsError) {
      return res.status(409).json({
        message: "Finish your jobs in progress before deactivating the account.",
        code: "ACTIVE_JOBS",
      });
    }
    console.error("Error deactivating user:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
