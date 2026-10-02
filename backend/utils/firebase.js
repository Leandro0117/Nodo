import admin from 'firebase-admin';
import serviceAccount from '../serviceAccount.js';
import { logRegistro, mask } from './debugLog.js';

const storageBucket = process.env.FIREBASE_STORAGE_BUCKET;

export const firebaseEnabled = serviceAccount !== null;
// El bucket sólo hace falta para Storage: sin él las notificaciones siguen
// funcionando, así que se degrada por separado.
export const storageEnabled = firebaseEnabled && Boolean(storageBucket);

if (firebaseEnabled && !storageBucket) {
  console.warn('⚠️  Falta FIREBASE_STORAGE_BUCKET. Storage deshabilitado.');
}

// Para verificar los tokens del registro por SMS basta con el ID del proyecto,
// sin credencial: sale de la variable, de la credencial o del nombre del bucket.
const projectId =
  process.env.FIREBASE_PROJECT_ID ||
  serviceAccount?.project_id ||
  storageBucket?.split('.')[0] ||
  'nodo-b1ff4';

let bucket = null;

if (firebaseEnabled) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket,
  });

  if (storageEnabled) {
    bucket = admin.storage().bucket();
  }
} else {
  // Sin credencial no hay Storage ni push, pero sí verificación de tokens:
  // las llaves públicas de Google se consultan por HTTPS.
  admin.initializeApp({ projectId });
}

console.log(
  `[firebase] Inicializado · proyecto ${projectId} · ` +
  (firebaseEnabled ? 'con credencial' : 'solo verificación de tokens (sin credencial)')
);

export default bucket;

/**
 * Verifica el ID token que la app obtiene de Firebase después de confirmar
 * el código SMS. Devuelve { phone, uid }: el teléfono verificado en formato
 * E.164 (+573001234567) y el uid del usuario que Firebase creó para esa
 * verificación. Lanza un error si el token es inválido, venció, es de otro
 * proyecto o no proviene de un inicio de sesión por teléfono.
 */
export async function verifyPhoneIdToken(idToken) {
  logRegistro(`Verificando token con Firebase (${idToken.length} caracteres)…`);

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    // Causas típicas: token de otro proyecto ("aud"), vencido o cortado.
    logRegistro(`✗ Firebase rechazó el token: [${error.code}] ${error.message}`);
    throw error;
  }

  logRegistro(
    `✓ Token válido · proyecto ${decoded.aud} · proveedor ${decoded.firebase?.sign_in_provider} · ` +
    `celular ${mask(decoded.phone_number)}`
  );

  if (decoded.firebase?.sign_in_provider !== 'phone' || !decoded.phone_number) {
    logRegistro('✗ El token no viene de un inicio de sesión por teléfono');
    throw new Error('The token does not come from a phone sign-in.');
  }

  return { phone: decoded.phone_number, uid: decoded.uid };
}

/**
 * Borra el usuario que Firebase creó al verificar el celular, y con él el
 * número guardado allá. Un usuario que ya no existe cuenta como borrado.
 * Sin credencial no se puede borrar: lanza un error para que el caller
 * conserve el uid y lo reintente más adelante.
 */
export async function deleteFirebaseUser(uid) {
  if (!firebaseEnabled) {
    throw new Error('Firebase sin credencial: no se puede borrar el usuario.');
  }

  try {
    await admin.auth().deleteUser(uid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
}

// Con estos códigos FCM avisa que el token ya no sirve: la app se desinstaló o
// el token rotó. Se distinguen del resto de errores porque el token hay que
// borrarlo — si queda en la base, cada envío posterior a ese usuario falla en
// silencio para siempre.
const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/// Devuelve { sent, invalidToken }. El caller es quien tiene el userId, así que
/// es quien debe limpiar el token cuando invalidToken es true.
export async function sendNotificationToUser(fcmToken, title, body, data = {}) {
  if (!firebaseEnabled) {
    console.log(`[firebase off] Notificación omitida → "${title}"`);
    return { sent: false, invalidToken: false };
  }

  try {
    const response = await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
    });

    return { sent: true, invalidToken: false, response };
  } catch (error) {
    const code = error.errorInfo?.code ?? error.code;

    if (INVALID_TOKEN_CODES.has(code)) {
      return { sent: false, invalidToken: true };
    }

    console.error('Error enviando notificación:', error);
    return { sent: false, invalidToken: false };
  }
}
