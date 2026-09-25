// Trazas del registro por SMS. Se apagan con DEBUG_REGISTRO=false en el .env.
const enabled = process.env.DEBUG_REGISTRO !== "false";

export function logRegistro(...args) {
  if (enabled) console.log(`[registro ${new Date().toISOString().slice(11, 23)}]`, ...args);
}

// Oculta el centro de un celular o token: "+573001234567" → "+573…4567"
export function mask(value, visible = 4) {
  const s = String(value ?? "");
  if (!s) return "(vacío)";
  if (s.length <= visible * 2) return s;
  return `${s.slice(0, visible)}…${s.slice(-visible)}`;
}
