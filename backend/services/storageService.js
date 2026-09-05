// services/storageService.js
import bucket, { firebaseEnabled } from "../utils/firebase.js";
import path from "path";
import { lookup } from "mime-types";

export async function generateUploadUrl(fileName) {
  if (!firebaseEnabled) {
    throw new Error('Firebase deshabilitado: falta backend/serviceAccount.json');
  }
  const file = bucket.file(`perfiles/${fileName.toLowerCase()}`);

  const extension = path.extname(fileName).toLowerCase();
  const contentType = lookup(extension) || "application/octet-stream";
  // Generar URL firmada válida por 15 minutos
  const [url] = await file.getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + 15 * 60 * 1000, // 15 minutos
    contentType,
  });

  return url;
}

/// Función para subir un archivo al bucket de Firebase Storage
async function uploadFile(localFilePath, destinationFileName) {
  await bucket.upload(localFilePath, {
    destination: destinationFileName,
    public: true, // Opcional: para que el archivo sea accesible públicamente
    metadata: {
      cacheControl: 'public, max-age=31536000',
    },
  });

  const file = bucket.file(destinationFileName);
  const publicUrl = `https://storage.googleapis.com/${bucket.name}/${destinationFileName}`;

  return publicUrl;
}
/*
// Ejemplo de uso:
uploadFile('./uploads/ejemplo.jpg', 'imagenes/ejemplo.jpg')
  .then(url => console.log('Archivo subido, URL pública:', url))
  .catch(err => console.error('Error al subir:', err));
*/

/// Elimina todos los archivos que cuelgan de un prefijo del bucket.
/// Firebase Storage no tiene carpetas reales: "publicaciones/<id>/" es sólo el
/// comienzo del nombre de cada objeto, así que se borran por prefijo.
export async function deleteFolder(prefix) {
  if (!firebaseEnabled) {
    console.warn(`[firebase off] No se eliminaron los archivos de "${prefix}"`);
    return;
  }

  await bucket.deleteFiles({ prefix });
}
