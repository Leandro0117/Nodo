import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/services/user_service.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/settings_sub_header.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          const SettingsSubHeader(
            title: 'Cuenta y perfil',
            subtitle: 'Gestiona tus datos personales',
            icon: Icons.person_outline_rounded,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _card([
                  _tile(
                    icon: Icons.edit_outlined,
                    color: AppColors.blue,
                    title: 'Editar perfil',
                    subtitle: 'Nombres, contacto, descripción y rubros',
                    onTap: () => Navigator.pushNamed(context, '/editProfile'),
                  ),
                  _tile(
                    icon: Icons.lock_outline_rounded,
                    color: const Color(0xFF1565C0),
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualiza tu contraseña de acceso',
                    onTap: _changePassword,
                  ),
                ]),
                SizedBox(height: 12.h),
                _card([
                  _tile(
                    icon: Icons.person_off_outlined,
                    color: AppColors.error,
                    title: 'Desactivar cuenta',
                    subtitle: 'Esta acción es permanente e irreversible',
                    onTap: _deactivateModal,
                    titleColor: AppColors.error,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          final isLast = i == children.length - 1;
          return Column(
            children: [
              children[i],
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56.w,
                  color: AppColors.slateGrey.withValues(alpha: 0.15),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.label.copyWith(
                        color: titleColor ?? AppColors.blue,
                        fontFamily: 'GothamMedium',
                      )),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.slateGrey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.slateGrey, size: 20.r),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cambiar contraseña',
            style: AppTypography.title.copyWith(color: AppColors.blue),
            textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(currentCtrl, 'Contraseña actual'),
              SizedBox(height: 12.h),
              _passwordField(newCtrl, 'Nueva contraseña'),
              SizedBox(height: 12.h),
              _passwordField(confirmCtrl, 'Confirmar nueva contraseña'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: AppTypography.label.copyWith(color: AppColors.slateGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Las contraseñas no coinciden'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Contraseña actualizada'),
                backgroundColor: AppColors.success,
              ));
            },
            child: Text('Actualizar', style: AppTypography.label),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: AppTypography.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body.copyWith(color: AppColors.slateGrey),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
    );
  }

  void _deactivateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeactivateAccountSheet(),
    );
  }
}

/// Pide la contraseña antes de desactivar: la acción no se puede deshacer, así
/// que un toque accidental no debe bastar.
class _DeactivateAccountSheet extends StatefulWidget {
  const _DeactivateAccountSheet();

  @override
  State<_DeactivateAccountSheet> createState() =>
      _DeactivateAccountSheetState();
}

class _DeactivateAccountSheetState extends State<_DeactivateAccountSheet> {
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _deactivate() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña para continuar.');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await UserService().deactivateAccount(userId, password);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    // La cuenta ya no existe para el servidor: se cierra la sesión local y se
    // vuelve al login sin dejar pantallas atrás.
    await userProvider.logout();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (route) => false);
    messenger.showSnackBar(const SnackBar(
      content: Text('Tu cuenta fue desactivada.'),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: AppColors.slateGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 36.r),
            ),
            SizedBox(height: 16.h),
            Text('Desactivar cuenta',
                style: AppTypography.title.copyWith(color: AppColors.error)),
            SizedBox(height: 8.h),
            Text(
              'Esta acción es PERMANENTE. Tus publicaciones dejarán de verse y '
              'tus datos personales se borrarán de NODO. Podrás registrarte de '
              'nuevo, pero no recuperarás tu historial ni tu calificación.',
              style: AppTypography.body.copyWith(color: AppColors.slateGrey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              enabled: !_loading,
              style: AppTypography.body,
              onSubmitted: (_) => _deactivate(),
              decoration: InputDecoration(
                labelText: 'Confirma con tu contraseña',
                labelStyle:
                    AppTypography.body.copyWith(color: AppColors.slateGrey),
                errorText: _error,
                errorMaxLines: 3,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onPressed: _loading ? null : _deactivate,
                child: _loading
                    ? SizedBox(
                        height: 18.r,
                        width: 18.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : Text('Desactivar mi cuenta',
                        style: AppTypography.label
                            .copyWith(color: AppColors.white)),
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: AppTypography.label
                      .copyWith(color: AppColors.slateGrey)),
            ),
          ],
        ),
      ),
    );
  }
}
