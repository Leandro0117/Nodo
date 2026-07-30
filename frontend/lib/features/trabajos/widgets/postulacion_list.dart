import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/posts/utils/post_format_utils.dart';
import 'package:nodo/features/trabajos/logic/job_service.dart';

class PostulacionList extends StatelessWidget {
  /// Cada item es `{'pub': {...}, 'postulacion': {...}}`.
  final List<Map<String, dynamic>> items;
  final Map<String, String> nombresClientes;
  final void Function(dynamic pub, String nombre) onVerDetalles;

  const PostulacionList({
    required this.items,
    required this.nombresClientes,
    required this.onVerDetalles,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) {
        final pub = items[i]['pub'];
        final post = items[i]['postulacion'];
        final nombre = nombresClientes[pub['clientId']?.toString()] ?? 'Cliente';
        return _PostulacionCard(
          publicacion: pub,
          postulacion: post,
          nombreCliente: nombre,
          onTap: () => onVerDetalles(pub, nombre),
        );
      },
    );
  }
}

class _PostulacionCard extends StatelessWidget {
  final dynamic publicacion;
  final dynamic postulacion;
  final String nombreCliente;
  final VoidCallback onTap;

  const _PostulacionCard({
    required this.publicacion,
    required this.postulacion,
    required this.nombreCliente,
    required this.onTap,
  });

  String get _status => postulacion?['status']?.toString() ?? 'pending';

  @override
  Widget build(BuildContext context) {
    final titulo = publicacion['title'] ?? 'Sin título';
    final descripcion = publicacion['description'] ?? '';
    final ubicacion = publicacion['location'] ?? '';
    final budget = publicacion['budget'];
    final tiempo = JobService.formatTimeAgo(publicacion['postDate'] ?? '');

    final photos = publicacion['photos'];
    final String? imageUrl =
        photos is List && photos.isNotEmpty ? photos.first.toString() : null;

    final categories = (publicacion['categories'] as List?) ?? [];
    final String categoria = categories.isNotEmpty
        ? (categories[0]['specificCategory']?['name'] ?? '')
        : '';

    final statusMeta = _statusMeta(_status);

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72.w,
                  height: 72.w,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              SizedBox(width: 12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: AppTypography.body.copyWith(
                              color: AppColors.blue,
                              fontFamily: 'GothamMedium',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _StatusChip(
                            label: statusMeta.label, color: statusMeta.color),
                      ],
                    ),
                    if (categoria.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      _MetaRow(Icons.category_outlined, categoria),
                    ],
                    if (ubicacion.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      _MetaRow(Icons.location_on_outlined, ubicacion),
                    ],
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        _MetaRow(Icons.access_time_rounded, tiempo),
                        const Spacer(),
                        if (budget != null)
                          Text(
                            '\$${formatBudget(budget)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.orange,
                              fontFamily: 'GothamBold',
                            ),
                          ),
                      ],
                    ),
                    if (descripcion.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        descripcion,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.slateGrey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.blue.withValues(alpha: 0.07),
      child: Center(
        child: Icon(
          Icons.work_outline_rounded,
          color: AppColors.blue.withValues(alpha: 0.3),
          size: 28.r,
        ),
      ),
    );
  }

  ({String label, Color color}) _statusMeta(String status) => switch (status) {
        'pending' => (label: 'Pendiente', color: const Color(0xFFF59E0B)),
        'accepted' => (label: 'En proceso', color: AppColors.blue),
        'rejected' => (label: 'Rechazado', color: Colors.redAccent),
        'finished' => (label: 'Finalizado', color: AppColors.slateGrey),
        _ => (label: status, color: AppColors.slateGrey),
      };
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontFamily: 'GothamMedium',
          fontSize: 10.sp,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.r, color: AppColors.slateGrey),
        SizedBox(width: 3.w),
        Flexible(
          child: Text(
            text,
            style:
                AppTypography.caption.copyWith(color: AppColors.slateGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
