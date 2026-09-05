import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/notifications_settings.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/constants/api_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedIndex = 0;
  late Future<List<dynamic>> _notificationsFuture;

  static const _tabs = [
    (label: 'Todo', icon: Icons.notifications_outlined),
    (label: 'Solicitudes', icon: Icons.assignment_outlined),
    (label: 'Reseñas', icon: Icons.star_outline_rounded),
    (label: 'Completados', icon: Icons.task_alt_outlined),
  ];

  static const _filterKeys = [
    'Todo',
    'Solicitudes',
    'Reseñas',
    'Trabajos Completados',
  ];

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<dynamic>> _fetchNotifications() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final response = await http.get(
      Uri.parse(
          ApiConstants.notificationsByUserId(userProvider.user?.id ?? '')),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load notifications');
  }

  void _refresh() => setState(() {
        _notificationsFuture = _fetchNotifications();
      });

  List<dynamic> _filterNotifications(
      List<dynamic> notifications, String filter) {
    switch (filter) {
      case 'Solicitudes':
        return notifications.where((n) => n['tipo'] == 'solicitud').toList();
      case 'Reseñas':
        return notifications.where((n) => n['tipo'] == 'reseña').toList();
      case 'Trabajos Completados':
        return notifications
            .where((n) => n['tipo'] == 'trabajo completado')
            .toList();
      default:
        return notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.alphaBlend(
          AppColors.blue.withValues(alpha: 0.03), Colors.white),
      body: Column(
        children: [
          _buildHeader(context),
          FutureBuilder<List<dynamic>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              final counts = _filterKeys
                  .map((k) => _filterNotifications(data, k).length)
                  .toList();
              return _buildTabs(counts);
            },
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _errorState('${snapshot.error}');
                }

                final all = snapshot.data ?? [];
                final filtered =
                    _filterNotifications(all, _filterKeys[_selectedIndex]);

                return RefreshIndicator(
                  color: AppColors.blue,
                  onRefresh: () async => _refresh(),
                  child: filtered.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16.r),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _NotificationCard(notification: filtered[index]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20.w, MediaQuery.of(context).padding.top + 16.h, 8.w, 20.h),
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificaciones',
                    style:
                        AppTypography.title.copyWith(color: AppColors.white)),
                SizedBox(height: 4.h),
                Text(
                  'Mantente al día con tu actividad',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.white, size: 22.r),
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: AppColors.white, size: 22.r),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsSettings()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<int> counts) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedIndex == i;
          final count = counts[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          _tabs[i].icon,
                          size: 18.r,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.blue.withValues(alpha: 0.5),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: EdgeInsets.all(2.r),
                              constraints: BoxConstraints(
                                  minWidth: 14.r, minHeight: 14.r),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.orange
                                    : AppColors.blue.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontFamily: 'GothamBold',
                                  fontSize: 8.sp,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.blue,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _tabs[i].label,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.blue.withValues(alpha: 0.6),
                        fontFamily:
                            isSelected ? 'GothamMedium' : 'GothamBook',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 60.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none_rounded,
                      size: 52.r,
                      color: AppColors.blue.withValues(alpha: 0.3)),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Sin notificaciones',
                  style: AppTypography.subtitle
                      .copyWith(color: AppColors.blue.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  'Aquí aparecerán tus notificaciones cuando tengas actividad.',
                  style:
                      AppTypography.body.copyWith(color: AppColors.slateGrey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48.r, color: AppColors.slateGrey),
            SizedBox(height: 12.h),
            Text(message,
                style:
                    AppTypography.body.copyWith(color: AppColors.slateGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: _iconColor(notification['tipo'])
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForType(notification['tipo']),
              color: _iconColor(notification['tipo']),
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['titulo'] ?? '',
                  style: AppTypography.label.copyWith(
                    color: AppColors.blue,
                    fontFamily: 'GothamMedium',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  notification['mensaje'] ?? '',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.slateGrey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 10.r, color: AppColors.slateGrey),
                    SizedBox(width: 3.w),
                    Text(
                      _formatDate(notification['fecha']),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.slateGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'solicitud':
        return Icons.assignment_outlined;
      case 'reseña':
        return Icons.star_outline_rounded;
      case 'trabajo completado':
        return Icons.task_alt_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'solicitud':
        return AppColors.blue;
      case 'reseña':
        return AppColors.orange;
      case 'trabajo completado':
        return AppColors.success;
      default:
        return AppColors.slateGrey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }
}
