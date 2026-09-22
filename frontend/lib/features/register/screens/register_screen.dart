import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/features/register/widgets/form_widget.dart';
import 'package:nodo/features/register/widgets/validation_widget.dart';
import 'package:nodo/features/register/widgets/profile_picture_widget.dart';
import 'package:nodo/features/login/screens/login_screen.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/core/utils/debug_log.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialUserType;

  const RegisterScreen({super.key, this.initialUserType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int currentStep = 0;

  static const _pasos = ['formulario', 'código SMS', 'foto de perfil', 'fin'];

  String _nombrePaso(int i) => i < _pasos.length ? _pasos[i] : 'fin';

  void nextStep() {
    logPaso('Pantalla', 'Paso ${currentStep + 1} (${_nombrePaso(currentStep)}) → '
        'paso ${currentStep + 2} (${_nombrePaso(currentStep + 1)})');
    setState(() {
      currentStep++;
    });

    // Si ya terminó, ir al login
    if (currentStep > 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget getStepWidget() {
    switch (currentStep) {
      case 0:
        return FormWidget(
          onContinue: nextStep,
          initialUserType: widget.initialUserType,
        );
      case 1:
        return ValidationWidget(onContinue: nextStep);
      case 2:
        return ProfilePictureWidget(onContinue: nextStep);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue, // Fondo azul detrás del contenido
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        toolbarHeight: 72.h,
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              'assets/icons/iconNodoWhite.png',
              width: 40.w,
              height: 40.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 12.w),
            Text(
              'Registro',
              style: AppTypography.title.copyWith(
                color: AppColors.white,
                // fontFamily: 'GothamBook',
              ),
            ),
          ],
        ),
        // centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              overlayColor: Colors.transparent,
            ),
            child: const Text('Tengo una cuenta'),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
          ),
        ),
        child: Stack(
          children: [
            // 🔹 Fondo con el logo
            Positioned.fill(
              child: Opacity(
                  opacity:
                      0.08, // 🔸 Ajusta la transparencia (0 = invisible, 1 = opaco)
                  child: Transform.scale(
                    scale: 2.sp,
                    child: Image.asset(
                      'assets/icons/iconNodoBlue.png', // cambia por la ruta de tu logo
                      fit: BoxFit.contain,
                      //alignment: Alignment.center,
                      height: 1800.h,
                      width: 1800.w,
                    ),
                  )),
            ),

            // 🔹 Contenido principal
            Column(
              children: [
                Expanded(
                  child: getStepWidget(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
