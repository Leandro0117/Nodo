import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/core/utils/debug_log.dart';
import 'package:nodo/features/register/logic/register_controller.dart';
import 'package:nodo/features/register/logic/validation_controller.dart';
import 'package:nodo/shared/widgets/elevated_button_widget.dart';

/// Paso 2 del registro: confirma el celular con un código SMS de Firebase y,
/// con el número ya verificado, crea la cuenta en el backend.
class ValidationWidget extends StatefulWidget {
  final VoidCallback onContinue;
  const ValidationWidget({super.key, required this.onContinue});

  @override
  State<ValidationWidget> createState() => _ValidationWidgetState();
}

class _ValidationWidgetState extends State<ValidationWidget> {
  late final ValidationController _controller;
  late final TapGestureRecognizer _resendRecognizer;

  /// Token de un número ya verificado. Se guarda para reintentar la creación
  /// de la cuenta (por ejemplo, tras un corte de red) sin pedir otro SMS.
  String? _verifiedToken;
  bool _creatingAccount = false;

  @override
  void initState() {
    super.initState();
    final phone = context.read<RegisterController>().pendingPhone ?? '';
    logPaso('Paso 2', 'Pantalla del código abierta · celular pendiente: ${enmascarar(phone)}');
    if (phone.isEmpty) {
      logPaso('Paso 2', '✗ No hay celular pendiente: el paso 1 no guardó los datos del formulario');
    }
    _controller = ValidationController(phone: phone);
    _resendRecognizer = TapGestureRecognizer()..onTap = _resend;
    // El SMS sale apenas se abre la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _resendRecognizer.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() =>
      _controller.sendCode(onAutoVerified: (token) {
        logPaso('Paso 2', 'Android verificó el celular solo; creando la cuenta');
        _completeRegistration(token);
      });

  void _resend() {
    logPaso('Paso 2', 'Botón "Reenviar" presionado (habilitado: ${_controller.canResend})');
    if (_controller.canResend) _send();
  }

  Future<void> _verify() async {
    logPaso('Paso 2', _verifiedToken != null
        ? 'Botón "Continuar": reintentando con el celular ya verificado'
        : 'Botón "Verificar" presionado');
    final idToken = _verifiedToken ?? await _controller.verify();
    if (idToken != null) await _completeRegistration(idToken);
  }

  Future<void> _completeRegistration(String idToken) async {
    if (_creatingAccount || !mounted) {
      logPaso('Paso 2', 'Creación de cuenta ignorada (ya en curso o pantalla cerrada)');
      return;
    }
    setState(() {
      _verifiedToken = idToken;
      _creatingAccount = true;
    });

    final created = await context
        .read<RegisterController>()
        .createAccount(context, phoneIdToken: idToken);

    if (!mounted) return;
    setState(() => _creatingAccount = false);

    if (created) {
      await _controller.finish();
      logPaso('Paso 2', '✓ Registro del celular completo. Pasando a la foto de perfil');
      widget.onContinue();
    } else {
      logPaso('Paso 2', '✗ El backend no creó la cuenta (ver el log de "Paso 2 · cuenta")');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth > 600 ? screenWidth * 0.1 : 16.0;
        final phoneVerified = _verifiedToken != null;
        final busy = _controller.isVerifying || _creatingAccount;

        return Center(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Verifica tu número',
                    style: AppTypography.title.copyWith(color: AppColors.blue),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    _subtitle(),
                    style: AppTypography.label.copyWith(color: AppColors.blue),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  _buildCodeFields(enabled: !phoneVerified && !busy),
                  if (_controller.error != null) ...[
                    SizedBox(height: 12.h),
                    Text(
                      _controller.error!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: screenWidth * 0.85,
                    child: CustomElevatedButton(
                      text: phoneVerified ? 'Continuar' : 'Verificar',
                      loading: busy,
                      onPressed: (_controller.codeSent || phoneVerified)
                          ? _verify
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!phoneVerified) _buildResend(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _subtitle() {
    final phone = _controller.maskedPhone;
    if (_verifiedToken != null) {
      return 'Número verificado. Estamos creando tu cuenta.';
    }
    if (_controller.codeSent) {
      return 'Te enviamos un SMS con un código de 6 dígitos al $phone.';
    }
    if (_controller.isSending) return 'Enviando un SMS al $phone...';
    return 'Vamos a enviarte un código por SMS al $phone.';
  }

  Widget _buildCodeFields({required bool enabled}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(ValidationController.codeLength, (index) {
        return SizedBox(
          width: 45.w,
          height: 55.h,
          child: TextField(
            controller: _controller.controllers[index],
            focusNode: _controller.focusNodes[index],
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints:
                index == 0 ? const [AutofillHints.oneTimeCode] : null,
            style: AppTypography.title,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueGrey),
              ),
            ),
            onChanged: (value) => _controller.onChanged(value, index),
          ),
        );
      }),
    );
  }

  Widget _buildResend() {
    final canResend = _controller.canResend;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '¿No recibiste el código? ',
            style: AppTypography.caption.copyWith(color: AppColors.blue),
          ),
          TextSpan(
            text: 'Reenviar',
            style: AppTypography.caption.copyWith(
              color: canResend ? AppColors.orange : AppColors.grey,
            ),
            recognizer: canResend ? _resendRecognizer : null,
          ),
          if (_controller.secondsRemaining > 0)
            TextSpan(
              text: ' en ${_controller.secondsRemaining}s',
              style: AppTypography.caption.copyWith(color: AppColors.blue),
            ),
        ],
      ),
    );
  }
}
