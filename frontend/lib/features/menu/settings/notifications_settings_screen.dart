import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'widgets/settings_sub_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool disableAll = false;
  String? activeNotification;
  String? selectedFrequency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          const SettingsSubHeader(
            title: 'Notificaciones',
            subtitle: 'Controla cómo y cuándo te avisamos',
            icon: Icons.notifications_outlined,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                // Descripción
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.blue, size: 16.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Elige cómo recibir notificaciones. Si las desactivas, aún podrás verlas en la sección de notificaciones.',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Desactivar todo
                _settingsCard([
                  _switchTile(
                    icon: Icons.do_not_disturb_on_outlined,
                    iconColor: AppColors.error,
                    title: 'Desactivar todas',
                    subtitle: 'Solo recibirás alertas importantes de tu cuenta',
                    value: disableAll,
                    onChanged: (val) => setState(() {
                      disableAll = val;
                      if (val) {
                        activeNotification = null;
                        selectedFrequency = null;
                      }
                    }),
                  ),
                ]),
                SizedBox(height: 12.h),

                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                  child: Text(
                    'MIS PUBLICACIONES',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.slateGrey,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _settingsCard([
                  _switchTile(
                    icon: Icons.campaign_outlined,
                    iconColor: AppColors.blue,
                    title: 'Notificaciones de publicaciones',
                    subtitle: 'Alertas sobre tus solicitudes publicadas',
                    value: activeNotification == 'publicaciones',
                    enabled: !disableAll,
                    onChanged: (_) => setState(() {
                      activeNotification = 'publicaciones';
                      selectedFrequency = null;
                    }),
                  ),
                  _switchTile(
                    icon: Icons.bolt_outlined,
                    iconColor: AppColors.orange,
                    title: 'Tiempo real',
                    subtitle: 'Notificación cada vez que se publique en tu rubro',
                    value: activeNotification == 'tiempoReal',
                    enabled: !disableAll,
                    onChanged: (_) => setState(() {
                      activeNotification = 'tiempoReal';
                      selectedFrequency = null;
                    }),
                  ),
                  _switchTile(
                    icon: Icons.summarize_outlined,
                    iconColor: const Color(0xFF00897B),
                    title: 'Resumen periódico',
                    subtitle: 'Recibe un resumen de nuevas publicaciones',
                    value: activeNotification == 'resumen',
                    enabled: !disableAll,
                    onChanged: (_) =>
                        setState(() => activeNotification = 'resumen'),
                  ),
                  if (activeNotification == 'resumen')
                    _frequencyPicker(),
                ]),
                SizedBox(height: 32.h),
              ],
            ),
          ),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
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

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: enabled ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: enabled
                    ? iconColor
                    : iconColor.withValues(alpha: 0.3),
                size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.label.copyWith(
                      color: enabled
                          ? AppColors.blue
                          : AppColors.slateGrey,
                      fontFamily: 'GothamMedium',
                    )),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.slateGrey)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.blue,
            inactiveThumbColor: AppColors.blue,
            inactiveTrackColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _frequencyPicker() {
    final options = [
      ('2h', 'Cada 2 horas'),
      ('6h', 'Cada 6 horas'),
      ('daily', 'Diariamente'),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
              height: 1,
              color: AppColors.slateGrey.withValues(alpha: 0.15)),
          SizedBox(height: 10.h),
          Text('Frecuencia',
              style: AppTypography.caption.copyWith(
                color: AppColors.slateGrey,
                letterSpacing: 0.8,
              )),
          SizedBox(height: 8.h),
          Row(
            children: options.map((opt) {
              final isSelected = selectedFrequency == opt.$1;
              return GestureDetector(
                onTap: () =>
                    setState(() => selectedFrequency = opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blue
                        : AppColors.blue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(opt.$2,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.blue,
                        fontFamily:
                            isSelected ? 'GothamMedium' : 'GothamBook',
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w,
          MediaQuery.of(context).padding.bottom + 12.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
          onPressed: () {},
          child: Text('Guardar preferencias', style: AppTypography.label),
        ),
      ),
    );
  }
}
