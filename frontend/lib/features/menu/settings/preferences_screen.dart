import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:nodo/core/services/user_service.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/models/location.dart';
import 'package:nodo/shared/providers/location_provider.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'widgets/settings_sub_header.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _userService = UserService();
  String idioma = 'Español';
  String? ubicacion;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user?.ubicacion is String) {
      ubicacion = user!.ubicacion as String;
    }
    context.read<LocationProvider>().cargarUbicaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          const SettingsSubHeader(
            title: 'Preferencias',
            subtitle: 'Idioma y ubicación de la app',
            icon: Icons.tune_rounded,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _card([
                  _tile(
                    icon: Icons.language_rounded,
                    color: const Color(0xFF00897B),
                    title: 'Idioma',
                    value: idioma,
                    onTap: _isSaving ? null : _editLanguage,
                  ),
                  _tile(
                    icon: Icons.location_on_outlined,
                    color: AppColors.blue,
                    title: 'Ubicación preferida',
                    value: _isSaving
                        ? 'Guardando...'
                        : (ubicacion ?? 'Sin seleccionar'),
                    onTap: _isSaving ? null : _editUbicacion,
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
    required String value,
    required VoidCallback? onTap,
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
                        color: AppColors.blue,
                        fontFamily: 'GothamMedium',
                      )),
                  SizedBox(height: 2.h),
                  Text(value,
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

  void _editLanguage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Idioma',
            style: AppTypography.title.copyWith(color: AppColors.blue),
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded,
                color: AppColors.blue.withValues(alpha: 0.3), size: 40.r),
            SizedBox(height: 12.h),
            Text(
              'NODO solo está disponible en español, pero solo por ahora 😉',
              style: AppTypography.body.copyWith(color: AppColors.slateGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Entendido', style: AppTypography.label),
            ),
          ),
        ],
      ),
    );
  }

  void _editUbicacion() async {
    final locations = context.read<LocationProvider>().locations;
    String? temp = ubicacion;

    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _UbicacionDialog(locations: locations, current: temp),
    );

    if (selected == null || selected == ubicacion) return;

    setState(() => _isSaving = true);
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user!;
      await _userService.updateUser(user.id, {'location': selected});
      final updatedUser = await _userService.getUser(user.id);
      userProvider.updateUsuario(updatedUser);
      if (mounted) setState(() => ubicacion = selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la ubicación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _UbicacionDialog extends StatefulWidget {
  final List<Location> locations;
  final String? current;

  const _UbicacionDialog({required this.locations, this.current});

  @override
  State<_UbicacionDialog> createState() => _UbicacionDialogState();
}

class _UbicacionDialogState extends State<_UbicacionDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Ubicación preferida',
          style: AppTypography.title.copyWith(color: AppColors.blue)),
      content: DropdownButtonFormField<String>(
        initialValue: widget.locations.any((l) => l.name == _selected)
            ? _selected
            : null,
        hint: Text('Selecciona un municipio',
            style: AppTypography.body.copyWith(color: AppColors.slateGrey)),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
          ),
        ),
        items: widget.locations
            .map((l) => DropdownMenuItem(
                value: l.name,
                child: Text(l.name,
                    style: AppTypography.body.copyWith(color: AppColors.blue))))
            .toList(),
        onChanged: (val) => setState(() => _selected = val),
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
          onPressed:
              _selected != null ? () => Navigator.pop(context, _selected) : null,
          child: Text('Guardar', style: AppTypography.label),
        ),
      ],
    );
  }
}
