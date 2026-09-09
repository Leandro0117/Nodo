import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const credentialsPath = join(__dirname, 'serviceAccount.json');

// En un despliegue (Railway, contenedores) no hay forma de subir el archivo,
// así que FIREBASE_SERVICE_ACCOUNT lo reemplaza. Acepta el JSON tal cual o
// codificado en base64, porque muchos paneles no admiten saltos de línea y la
// clave privada tiene varios.
function credentialsFromEnv() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();
  if (!raw) return null;

  const json = raw.startsWith('{') ? raw : Buffer.from(raw, 'base64').toString('utf-8');
  return JSON.parse(json);
}

let credentials = null;

try {
  credentials = credentialsFromEnv();

  if (!credentials && existsSync(credentialsPath)) {
    credentials = JSON.parse(readFileSync(credentialsPath, 'utf-8'));
  }
} catch (error) {
  // Credenciales presentes pero ilegibles: se avisa y se sigue en modo
  // degradado, igual que si no estuvieran.
  console.error('⚠️  Credenciales de Firebase inválidas:', error.message);
  credentials = null;
}

if (!credentials) {
  console.warn(
    '⚠️  Sin credenciales de Firebase (ni FIREBASE_SERVICE_ACCOUNT ni ' +
    'serviceAccount.json). Firebase deshabilitado: sin push notifications ' +
    'ni subida de imágenes.'
  );
}

export default credentials;
