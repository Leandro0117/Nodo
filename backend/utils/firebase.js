import admin from 'firebase-admin';
import serviceAccount from '../serviceAccount.js';

export const firebaseEnabled = serviceAccount !== null;

let bucket = null;

if (firebaseEnabled) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: 'nodo-b1ff4.firebasestorage.app',
  });
  bucket = admin.storage().bucket();
}

export default bucket;

export async function sendNotificationToUser(fcmToken, title, body, data = {}, userId = null) {
  if (!firebaseEnabled) {
    console.log(`[firebase off] Notificación omitida → "${title}"`);
    return null;
  }

  const message = {
    token: fcmToken,
    notification: { title, body },
    data,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Notificación enviada:', response);
    return response;
  } catch (error) {
    console.error('Error enviando notificación:', error);
    return null;
  }
}