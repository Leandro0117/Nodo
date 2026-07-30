import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/posts/utils/post_format_utils.dart';
import 'package:nodo/features/trabajos/logic/job_service.dart';

class JobList extends StatelessWidget {
  final List publicaciones;
  final Map<String, String> nombresClientes;
  final void Function(dynamic, String) onVerDetalles;

  const JobList({
    required this.publicaciones,
    required this.nombresClientes,
    required this.onVerDetalles,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rowCount = (publicaciones.length / 2).ceil();
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final left = publicaciones[rowIndex * 2];
        final right = rowIndex * 2 + 1 < publicaciones.length
            ? publicaciones[rowIndex * 2 + 1]
            : null;

        Widget buildCard(dynamic pub) {
          final nombre = nombresClientes[pub['clientId']] ?? 'Cliente';
          return _JobCard(
            publicacion: pub,
            nombreCliente: nombre,
            onTap: () => onVerDetalles(pub, nombre),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: buildCard(left)),
                SizedBox(width: 10.w),
                if (right != null)
                  Expanded(child: buildCard(right))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final dynamic publicacion;
  final String nombreCliente;
  final VoidCallback onTap;

  const _JobCard({
    required this.publicacion,
    required this.nombreCliente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photos = publicacion['photos'];
    final List<String> imagenes = photos is List && photos.isNotEmpty
        ? photos.map<String>((e) => e.toString()).toList()
        : [];

    final String titulo = publicacion['title'] ?? 'Sin título';
    final String descripcion = publicacion['description'] ?? '';
    final String ubicacion = publicacion['location'] ?? '';
    final String tiempo =
        JobService.formatTimeAgo(publicacion['postDate'] ?? '');
    final budget = publicacion['budget'];
    final String presupuesto =
        budget != null ? '\$${formatBudget(budget)}' : '';

    final categories = (publicacion['categories'] as List?) ?? [];
    final String categoria = categories.isNotEmpty
        ? (categories[0]['specificCategory']?['name'] ?? '')
        : '';

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 2.0,
                child: imagenes.isNotEmpty
                    ? Image.network(
                        imagenes.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : _loadingPlaceholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: AppTypography.body.copyWith(color: AppColors.blue),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (descripcion.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      descripcion,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.slateGrey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 6.h),
                  if (categoria.isNotEmpty) ...[
                    _infoRow(Icons.category_outlined, categoria,
                        AppColors.slateGrey),
                    SizedBox(height: 3.h),
                  ],
                  if (ubicacion.isNotEmpty) ...[
                    _infoRow(Icons.location_on_outlined, ubicacion,
                        AppColors.slateGrey),
                    SizedBox(height: 3.h),
                  ],
                  _infoRow(Icons.person_outline_rounded, nombreCliente,
                      AppColors.slateGrey),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Expanded(
                        child: _infoRow(Icons.access_time_rounded, tiempo,
                            AppColors.slateGrey),
                      ),
                      if (presupuesto.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            presupuesto,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.orange,
                              fontFamily: 'GothamMedium',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 10.r, color: color),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.blue.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.work_outline_rounded,
          color: AppColors.blue.withValues(alpha: 0.3),
          size: 36.r,
        ),
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: AppColors.blue.withValues(alpha: 0.04),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
