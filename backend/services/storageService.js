// services/storageService.js
import bucket, { storageEnabled } from "../utils/firebase.js";
import path from "path";
import { lookup } from "mime-types";

export async function generateUploadUrl(fileName, contentType) {
  if (!storageEnabled) {
    throw new Error(
      'Storage deshabilitado: faltan las credenciales de Firebase o FIREBASE_STORAGE_BUCKET'
    );
  }
  const file = bucket.file(`perfiles/${fileName.toLowerCase()}`);

  // El cliente sube con este mismo Content-Type. Si el que se firma acá y el
  // que viaja en el PUT no coinciden, GCS rechaza la subida entera con
  // SignatureDoesNotMatch, así que manda el del cliente y sólo se deduce por
  // extensión cuando no lo envía.
  const extension = path.extname(fileName).toLowerCase();
  const resolvedContentType =
    contentType || lookup(extension) || "application/octet-stream";

  // Generar URL firmada válida por 15 minutos
  const [url] = await file.getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + 15 * 60 * 1000, // 15 minutos
    contentType: resolvedContentType,
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
  if (!storageEnabled) {
    console.warn(`[storage off] No se eliminaron los archivos de "${prefix}"`);
    return;
  }

  await bucket.deleteFiles({ prefix });
}
