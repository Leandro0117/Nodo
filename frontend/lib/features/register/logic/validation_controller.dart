import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nodo/core/services/phone_auth_service.dart';
import 'package:nodo/core/utils/debug_log.dart';

/// Estado de la pantalla del código de 6 dígitos.
///
/// Vive solo mientras la pantalla está abierta: lo crea [ValidationWidget]
/// y lo libera al salir, así que cada registro empieza limpio.
class ValidationController extends ChangeNotifier {
  ValidationController({required this.phone, PhoneAuthService? service})
      : _service = service ?? PhoneAuthService();

  /// Celular en formato local (10 dígitos), tal como lo escribió el usuario.
  final String phone;
  final PhoneAuthService _service;

  static const int codeLength = 6;
  static const int resendSeconds = 60;

  final List<TextEditingController> controllers =
      List.generate(codeLength, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
      List.generate(codeLength, (_) => FocusNode());

  bool isSending = false;
  bool isVerifying = false;
  bool codeSent = false;
  String? error;
  int secondsRemaining = 0;

  Timer? _timer;
  bool _disposed = false;

  bool get canResend => secondsRemaining == 0 && !isSending;

  String get enteredCode => controllers.map((c) => c.text).join();

  /// "+57 300 *** 4567": muestra a dónde llegó el SMS sin exponer el número.
  String get maskedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return phone;
    return '+57 ${digits.substring(0, 3)} *** ${digits.substring(6)}';
  }

  Future<void> sendCode({void Function(String idToken)? onAutoVerified}) async {
    if (isSending) {
      logPaso('Paso 2', 'Ya hay un envío en curso; se ignora la nueva solicitud');
      return;
    }
    logPaso('Paso 2', 'Solicitando SMS…');
    isSending = true;
    error = null;
    _notify();

    try {
      await _service.sendCode(phone, onAutoVerified: onAutoVerified);
      codeSent = true;
      _clearCode();
      _startCountdown();
      logPaso('Paso 2', '✓ SMS en camino. "Reenviar" se habilita en ${resendSeconds}s');
    } catch (e) {
      error = PhoneAuthService.friendlyError(e);
      logPaso('Paso 2', '✗ No se pudo enviar el SMS: $e');
      logPaso('Paso 2', 'Mensaje mostrado al usuario: "$error"');
    } finally {
      isSending = false;
      _notify();
    }
  }

  /// Devuelve el ID token si el código es correcto; si no, deja el motivo en [error].
  Future<String?> verify() async {
    if (enteredCode.length != codeLength) {
      logPaso('Paso 2', '✗ Código incompleto (${enteredCode.length}/$codeLength dígitos)');
      error = 'Escribe los $codeLength dígitos del código.';
      _notify();
      return null;
    }

    isVerifying = true;
    error = null;
    _notify();

    try {
      final token = await _service.verifyCode(enteredCode);
      logPaso('Paso 2', '✓ Código aceptado por Firebase');
      return token;
    } catch (e) {
      error = PhoneAuthService.friendlyError(e);
      logPaso('Paso 2', '✗ Código rechazado: $e');
      return null;
    } finally {
      isVerifying = false;
      _notify();
    }
  }

  /// Cierra la sesión temporal de Firebase una vez creada la cuenta.
  Future<void> finish() => _service.signOut();

  void onChanged(String value, int index) {
    if (value.length > 1) {
      // Escribió encima de la última casilla: conservar el dígito nuevo.
      if (index == codeLength - 1) {
        controllers[index].text = value.substring(value.length - 1);
        return;
      }
      // Pegó o autocompletó el código en una casilla: repartirlo.
      var last = index;
      for (var i = 0; i < value.length && index + i < codeLength; i++) {
        controllers[index + i].text = value[i];
        last = index + i;
      }
      if (last < codeLength - 1) {
        focusNodes[last + 1].requestFocus();
      } else {
        focusNodes[last].unfocus();
      }
      return;
    }

    if (value.isNotEmpty && index < codeLength - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  void _clearCode() {
    for (final c in controllers) {
      c.clear();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    secondsRemaining = resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining--;
      if (secondsRemaining <= 0) {
        secondsRemaining = 0;
        timer.cancel();
      }
      _notify();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
