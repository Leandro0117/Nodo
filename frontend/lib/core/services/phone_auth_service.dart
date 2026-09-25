import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:nodo/core/utils/debug_log.dart';

/// Verificación del celular por SMS con Firebase Authentication.
///
/// Nodo no usa Firebase para iniciar sesión: solo para confirmar que el
/// celular es de quien se registra. [verifyCode] devuelve un ID token que el
/// backend valida antes de crear la cuenta; después se cierra la sesión.
class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Si Firebase no responde en este tiempo, se corta con un error visible
  /// en vez de dejar la pantalla esperando para siempre.
  static const _sendTimeout = Duration(seconds: 90);

  String? _verificationId; // Android e iOS
  int? _resendToken; // solo Android
  ConfirmationResult? _webConfirmation; // web

  /// Convierte un celular colombiano al formato que exige Firebase.
  /// "300 123 4567" → "+573001234567".
  static String toE164(String localPhone) {
    final digits = localPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('57')) return '+$digits';
    return '+57$digits';
  }

  /// Envía el SMS y termina cuando Firebase confirma el envío.
  ///
  /// En Android, Google Play Services a veces lee el SMS sin que el usuario
  /// escriba nada; en ese caso [onAutoVerified] recibe directamente el token.
  Future<void> sendCode(
    String localPhone, {
    void Function(String idToken)? onAutoVerified,
  }) async {
    final phone = toE164(localPhone);
    final plataforma = kIsWeb ? 'web' : defaultTargetPlatform.name;
    logPaso('SMS', 'Enviando código a ${enmascarar(phone)} · plataforma: $plataforma');
    logPaso('SMS', 'Proyecto de Firebase en la app: ${Firebase.app().options.projectId} '
        '(debe ser nodo-b1ff4)');

    if (kIsWeb) {
      logPaso('SMS', 'Llamando signInWithPhoneNumber: debería aparecer el reCAPTCHA…');
      _webConfirmation = await _auth
          .signInWithPhoneNumber(phone)
          .timeout(_sendTimeout, onTimeout: () => throw _timeout('reCAPTCHA / envío web'));
      logPaso('SMS', '✓ Firebase confirmó el envío del SMS (web)');
      return;
    }

    final sent = Completer<void>();

    logPaso('SMS', 'Llamando verifyPhoneNumber…');
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        logPaso('SMS', '✓ verificationCompleted: Android leyó el SMS sin intervención');
        if (!sent.isCompleted) sent.complete();
        try {
          final token = await _signInAndGetToken(credential);
          onAutoVerified?.call(token);
        } catch (e) {
          // Si falla, el usuario todavía puede escribir el código a mano.
          logPaso('SMS', '✗ La verificación automática falló: $e');
        }
      },
      verificationFailed: (error) {
        logPaso('SMS', '✗ verificationFailed: [${error.code}] ${error.message}');
        if (!sent.isCompleted) sent.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        logPaso('SMS', '✓ codeSent: SMS enviado · resendToken: '
            '${resendToken == null ? "no (normal en iOS)" : "sí"}');
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!sent.isCompleted) sent.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        logPaso('SMS', 'codeAutoRetrievalTimeout: Android dejó de esperar el SMS '
            '(normal: el usuario lo escribe a mano)');
        _verificationId = verificationId;
      },
    );
    logPaso('SMS', 'verifyPhoneNumber aceptado, esperando respuesta de Firebase…');

    return sent.future.timeout(
      _sendTimeout,
      onTimeout: () => throw _timeout('verifyPhoneNumber'),
    );
  }

  /// Valida el código de 6 dígitos y devuelve el ID token de Firebase.
  Future<String> verifyCode(String smsCode) async {
    logPaso('SMS', 'Verificando el código ingresado…');

    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) {
        logPaso('SMS', '✗ No hay envío previo en web (_webConfirmation es null)');
        throw StateError('Primero hay que enviar el código.');
      }
      final result = await confirmation.confirm(smsCode);
      return _idTokenOf(result.user);
    }

    final verificationId = _verificationId;
    if (verificationId == null) {
      logPaso('SMS', '✗ No hay verificationId: el SMS nunca se confirmó como enviado');
      throw StateError('Primero hay que enviar el código.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _signInAndGetToken(credential);
  }

  /// Cierra la sesión temporal de Firebase una vez creada la cuenta.
  Future<void> signOut() {
    logPaso('SMS', 'Cerrando la sesión temporal de Firebase');
    return _auth.signOut();
  }

  Future<String> _signInAndGetToken(PhoneAuthCredential credential) async {
    final result = await _auth.signInWithCredential(credential);
    return _idTokenOf(result.user);
  }

  Future<String> _idTokenOf(User? user) async {
    logPaso('SMS', '✓ Código correcto · uid ${user?.uid} · '
        'celular confirmado ${enmascarar(user?.phoneNumber)}');
    final token = await user?.getIdToken();
    if (token == null) {
      logPaso('SMS', '✗ Firebase no devolvió ID token');
      throw StateError('Firebase no devolvió un token de verificación.');
    }
    logPaso('SMS', '✓ ID token obtenido: ${enmascarar(token, visibles: 6)}');
    return token;
  }

  TimeoutException _timeout(String etapa) {
    logPaso('SMS', '✗ Pasaron ${_sendTimeout.inSeconds} s sin respuesta de Firebase en '
        '"$etapa". Revisa que el proveedor Phone esté activo, la huella SHA-1 '
        '(Android) o que el reCAPTCHA haya cargado (web).');
    return TimeoutException('Firebase no respondió', _sendTimeout);
  }

  /// Traduce los errores de Firebase a mensajes para el usuario.
  static String friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'Firebase no respondió. Revisa tu conexión e inténtalo de nuevo.';
    }
    if (error is FirebaseAuthException) {
      debugPrint('FirebaseAuth [${error.code}]: ${error.message}');

      switch (error.code) {
        case 'invalid-phone-number':
          return 'El número de celular no es válido.';
        case 'invalid-verification-code':
          return 'El código no es correcto. Revísalo e inténtalo de nuevo.';
        case 'session-expired':
        case 'invalid-verification-id':
          return 'El código venció. Pide uno nuevo.';
        case 'too-many-requests':
          return 'Hiciste demasiados intentos. Espera unos minutos y vuelve a intentarlo.';
        case 'quota-exceeded':
          return 'No pudimos enviar el SMS en este momento. Inténtalo más tarde.';
        case 'network-request-failed':
          return 'No hay conexión a internet. Revísala e inténtalo de nuevo.';
        case 'captcha-check-failed':
          return 'No se pudo completar la verificación de seguridad. Recarga la página e inténtalo de nuevo.';
        // Errores de configuración del proyecto, no del usuario. El código
        // exacto queda en la consola por el debugPrint de arriba.
        case 'operation-not-allowed':
        case 'billing-not-enabled':
        case 'missing-client-identifier':
        case 'app-not-authorized':
          return 'La verificación por SMS no está disponible en este momento.';
      }
    }
    debugPrint('Error no reconocido en la verificación: $error');
    return 'No pudimos verificar tu número. Inténtalo de nuevo.';
  }
}
