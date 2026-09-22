import 'package:flutter/foundation.dart';

/// Traza del flujo de registro por SMS. Solo imprime en modo debug.
///
/// Ejemplo: logPaso('SMS', 'Código enviado')
///   → [REGISTRO 14:03:22.481] SMS › Código enviado
///
/// Para ver solo estas líneas: en la consola de Chrome filtra por "REGISTRO";
/// en la terminal, busca ese mismo texto en la salida de `flutter run`.
void logPaso(String area, String mensaje) {
  if (!kDebugMode) return;
  final hora = DateTime.now().toIso8601String().substring(11, 23);
  debugPrint('[REGISTRO $hora] $area › $mensaje');
}

/// Oculta el centro de un celular o un token para no dejarlo completo en los logs.
/// "+573001234567" → "+573…4567 (13 caracteres)"
String enmascarar(String? valor, {int visibles = 4}) {
  if (valor == null || valor.isEmpty) return '(vacío)';
  if (valor.length <= visibles * 2) return valor;
  return '${valor.substring(0, visibles)}…'
      '${valor.substring(valor.length - visibles)} (${valor.length} caracteres)';
}
