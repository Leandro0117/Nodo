import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:nodo/features/login/logic/login_controller.dart';
import 'package:nodo/features/login/screens/forgot_password_screen.dart';
import 'package:nodo/features/register/screens/register_screen.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/user_provider.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/shared/widgets/elevated_button_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identificadorController =
      TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  bool _obscurePassword = true;

  late LoginController _loginController;

  @override
  void initState() {
    super.initState();
    _loginController = LoginController(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          // — Header —
          SizedBox(
            height: 207.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(100),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    'assets/icons/iconNodoWhite.png',
                    width: 55.w,
                    height: 55.h,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 103.5.h),
                    child: AutoSizeText(
                      'Inicia sesión y descubre nuevas oportunidades de trabajo y servicios en un solo lugar',
                      textAlign: TextAlign.center,
                      style: AppTypography.title.copyWith(color: AppColors.white),
                      maxLines: 3,
                      minFontSize: 5,
                      maxFontSize: 22,
                    ),
                  )
                ],
              ),
            ),
          ),

          // — Formulario —
          Container(
            margin: EdgeInsets.symmetric(horizontal: 30.6.w).copyWith(
              top: 40.h,
              bottom: 30.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo correo / teléfono
                TextField(
                  controller: _identificadorController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico o teléfono",
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.slateGrey,
                      size: 20.sp,
                    ),
                  ),
                ),

                SizedBox(height: 14.h),

                // Campo contraseña
                TextField(
                  controller: _contrasenaController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.slateGrey,
                      size: 20.sp,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                // Olvidaste contraseña
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "¿Olvidaste tu contraseña?",
                      style: AppTypography.body.copyWith(color: AppColors.orange),
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // Botón iniciar sesión
                Selector<UserProvider, bool>(
                  selector: (_, provider) => provider.isLoading,
                  builder: (_, loading, __) => CustomElevatedButton(
                    text: "Iniciar sesión",
                    onPressed: loading
                        ? null
                        : () async {
                            await _loginController.login(
                              _identificadorController.text.trim(),
                              _contrasenaController.text.trim(),
                            );
                          },
                    loading: loading,
                  ),
                ),

                SizedBox(height: 4.h),

                // ¿No tienes cuenta?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No tienes una cuenta? ",
                      style: AppTypography.body.copyWith(color: AppColors.blue),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Regístrate",
                        style: AppTypography.body.copyWith(
                          color: AppColors.orange,
                          fontFamily: 'GothamMedium',
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                // // Divisor "O continua con"
                // Row(
                //   children: [
                //     Expanded(
                //       child: Divider(
                //         color: AppColors.slateGrey.withOpacity(0.5),
                //         thickness: 1,
                //       ),
                //     ),
                //     Padding(
                //       padding: EdgeInsets.symmetric(horizontal: 12.w),
                //       child: Text(
                //         "O continúa con",
                //         style: AppTypography.caption.copyWith(
                //           color: AppColors.slateGrey,
                //         ),
                //       ),
                //     ),
                //     Expanded(
                //       child: Divider(
                //         color: AppColors.slateGrey.withOpacity(0.5),
                //         thickness: 1,
                //       ),
                //     ),
                //   ],
                // ),

                // SizedBox(height: 20.h),

                // // Íconos sociales
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     _SocialIconButton(
                //       icon: Icons.facebook,
                //       isFontAwesome: false,
                //       onTap: () {},
                //     ),
                //     SizedBox(width: 20.w),
                //     _SocialIconButton(
                //       faIcon: FontAwesomeIcons.google,
                //       isFontAwesome: true,
                //       onTap: () {},
                //     ),
                //     SizedBox(width: 20.w),
                //     _SocialIconButton(
                //       faIcon: FontAwesomeIcons.linkedin,
                //       isFontAwesome: true,
                //       onTap: () {},
                //     ),
                //   ],
                // ),

                // SizedBox(height: 24.h),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Ícono social con borde circular y efecto ripple
class _SocialIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isFontAwesome;
  final IconData? icon;
  final IconData? faIcon;

  const _SocialIconButton({
    required this.onTap,
    required this.isFontAwesome,
    this.icon,
    this.faIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.slateGrey.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Center(
          child: isFontAwesome
              ? FaIcon(faIcon as FaIconData?, size: 18.sp, color: AppColors.blue)
              : Icon(icon, size: 22.sp, color: AppColors.blue),
        ),
      ),
    );
  }
}
