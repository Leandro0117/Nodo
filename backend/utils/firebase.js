import admin from 'firebase-admin';
import serviceAccount from '../serviceAccount.js';

const storageBucket = process.env.FIREBASE_STORAGE_BUCKET;

export const firebaseEnabled = serviceAccount !== null;
// El bucket sólo hace falta para Storage: sin él las notificaciones siguen
// funcionando, así que se degrada por separado.
export const storageEnabled = firebaseEnabled && Boolean(storageBucket);

if (firebaseEnabled && !storageBucket) {
  console.warn('⚠️  Falta FIREBASE_STORAGE_BUCKET. Storage deshabilitado.');
}

let bucket = null;

if (firebaseEnabled) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket,
  });

  if (storageEnabled) {
    bucket = admin.storage().bucket();
  }
}

export default bucket;

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
