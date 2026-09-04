import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const credentialsPath = join(__dirname, 'serviceAccount.json');

let credentials = null;

if (existsSync(credentialsPath)) {
  credentials = JSON.parse(readFileSync(credentialsPath, 'utf-8'));
} else {
  console.warn(
    '⚠️  serviceAccount.json no encontrado. Firebase deshabilitado: ' +
    'sin push notifications ni subida de imágenes.'
  );
}

export default credentials;