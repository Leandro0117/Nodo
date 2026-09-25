import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/chat/screens/chat_1.dart';
import 'package:nodo/features/rating/logic/rating_service.dart';
import 'package:nodo/features/rating/widgets/rating_dialog.dart';
import 'package:nodo/features/rating/widgets/rating_section_widget.dart';
import 'package:nodo/features/trabajos/logic/job_service.dart';
import 'package:nodo/features/trabajos/screens/report_screen.dart';
import 'package:nodo/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool desdePostulaciones;
  final Map<String, dynamic>? postulacion;
  final VoidCallback? onPostulacionCambiada;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.postulacion,
    this.desdePostulaciones = false,
    this.onPostulacionCambiada,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  int _currentIndex = 0;
  late List<String> _images;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  bool _workerHasConfirmed = false;
  bool _clientHasConfirmed = false;
  bool _serviceCompleted = false;

  // — Calificación —
  String? _serviceId;
  String? _ratedUserId;   // ID del usuario que el trabajador debe calificar (cliente)
  bool _hasRated = false;
  int _myScore = 0;

  @override
  void initState() {
    super.initState();
    final raw = widget.job['images'];
    final all =
        raw is List ? List<String>.from(raw) : [raw?.toString() ?? ''];
    _images = all.where((u) => u.isNotEmpty).toList();

    final service = widget.postulacion?['service'] as Map<String, dynamic>?;
    _workerHasConfirmed =
        service?['workerCompletionRequest'] as bool? ?? false;
    _clientHasConfirmed =
        service?['clientCompletionRequest'] as bool? ?? false;
    _serviceCompleted = service?['status']?.toString() == 'completed';

    _serviceId = service?['id']?.toString();
    // El cliente está en postulacion['post']['clientId'] o en job['clientId']
    final post = widget.postulacion?['post'] as Map<String, dynamic>?;
    _ratedUserId = post?['clientId']?.toString();

    if (_serviceCompleted && _serviceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyRating());
    }
  }

  String get _nombreSolo {
    final nombre = widget.job['user']?.toString() ?? 'Cliente';
    return nombre.contains(':') ? nombre.split(':').last.trim() : nombre;
  }

  Future<void> _loadMyRating() async {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
    if (_serviceId == null || userId.isEmpty) return;
    final rating = await RatingService.getMyRating(_serviceId!, userId);
    if (!mounted) return;
    if (rating != null) {
      setState(() {
        _hasRated = true;
        _myScore = (rating['score'] as num?)?.toInt() ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String clienteNombre =
        widget.job['user']?.toString() ?? 'Cliente desconocido';
    final String nombreSolo = clienteNombre.contains(':')
        ? clienteNombre.split(':').last.trim()
        : clienteNombre;

    final String titulo = widget.job['title'] ?? 'Sin título';
    final String descripcion =
        widget.job['description'] ?? 'Sin descripción';
    final String ubicacion = widget.job['location'] ?? '';
    final String presupuesto = widget.job['price'] ?? '';
    final String fechaLimite = widget.job['time'] ?? '';
    final String estadoPostulacion =
        widget.postulacion?['status']?.toString() ?? '';

    return Scaffold(
      backgroundColor:
          Color.alphaBlend(AppColors.blue.withValues(alpha: 0.03), Colors.white),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.blue),
        title: Text(
          'Detalle de servicio',
          style: AppTypography.title.copyWith(color: AppColors.orange),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageCarousel(),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: AppTypography.title
                                .copyWith(color: AppColors.blue),
                          ),
                        ),
                        if (estadoPostulacion.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          _buildStatusChip(estadoPostulacion),
                        ],
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      descripcion,
                      style: AppTypography.body.copyWith(
                          color: AppColors.blue.withValues(alpha: 0.85),
                          height: 1.45),
                    ),
                    SizedBox(height: 16.h),
                    Divider(
                        color: AppColors.slateGrey.withValues(alpha: 0.3)),
                    SizedBox(height: 8.h),
                    if (ubicacion.isNotEmpty)
                      _buildInfoRow(
                          Icons.location_on_outlined, 'Ubicación', ubicacion),
                    if (fechaLimite.isNotEmpty)
                      _buildInfoRow(
                          Icons.event_outlined, 'Fecha límite', fechaLimite),
                    if (presupuesto.isNotEmpty)
                      _buildInfoRow(
                          Icons.attach_money, 'Presupuesto', presupuesto),
                    _buildInfoRow(
                        Icons.person_outline, 'Cliente', clienteNombre),
                    if (estadoPostulacion == 'accepted' && !_serviceCompleted) ...[
                      SizedBox(height: 16.h),
                      _buildCompletionStatusPanel(nombreSolo),
                    ],
                    SizedBox(height: 20.h),
                    _buildActionButtons(estadoPostulacion, nombreSolo),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image carousel ────────────────────────────────────────────────────────

  Widget _buildImageCarousel() {
    if (_images.isEmpty) {
      return Container(
        height: 220.h,
        color: AppColors.blue.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 36.sp, color: AppColors.blue.withValues(alpha: 0.4)),
            SizedBox(height: 8.h),
            Text(
              'Sin imágenes',
              style: AppTypography.body.copyWith(color: AppColors.blue),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          items: _images.map((url) {
            return Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.blue.withValues(alpha: 0.06),
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_outlined,
                    size: 36.sp,
                    color: AppColors.blue.withValues(alpha: 0.35)),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 220.h,
            viewportFraction: 1,
            enlargeCenterPage: false,
            enableInfiniteScroll: _images.length > 1,
            onPageChanged: (index, _) =>
                setState(() => _currentIndex = index),
          ),
        ),
        if (_images.length > 1)
          Positioned(
            bottom: 12.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _images.asMap().entries.map((entry) {
                final isActive = _currentIndex == entry.key;
                return GestureDetector(
                  onTap: () =>
                      _carouselController.animateToPage(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 9.w : 7.w,
                    height: isActive ? 9.w : 7.w,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.orange : AppColors.white,
                      border:
                          Border.all(color: AppColors.white, width: 1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: AppColors.orange),
          SizedBox(width: 10.w),
          Text(
            '$label: ',
            style: AppTypography.body.copyWith(color: AppColors.blue),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status chip ───────────────────────────────────────────────────────────

  Widget _buildStatusChip(String status) {
    final (label, color) = switch (status) {
      'accepted' => ('Aceptado', AppColors.success),
      'rejected' => ('Rechazado', AppColors.error),
      'pending' => ('Pendiente', AppColors.orange),
      _ => (status, AppColors.slateGrey),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }

  // ── Completion status panel ───────────────────────────────────────────────

  Widget _buildCompletionStatusPanel(String clienteName) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado de finalización',
            style: AppTypography.label.copyWith(color: AppColors.blue),
          ),
          SizedBox(height: 10.h),
          _buildConfirmationRow(
            icon: Icons.construction_outlined,
            label: 'Tú',
            confirmed: _workerHasConfirmed,
          ),
          SizedBox(height: 6.h),
          _buildConfirmationRow(
            icon: Icons.person_outline,
            label: clienteName,
            confirmed: _clientHasConfirmed,
          ),
          if (_workerHasConfirmed && !_clientHasConfirmed) ...[
            SizedBox(height: 10.h),
            Text(
              'Esperando confirmación del cliente…',
              style:
                  AppTypography.caption.copyWith(color: AppColors.slateGrey),
            ),
          ],
          if (!_workerHasConfirmed && _clientHasConfirmed) ...[
            SizedBox(height: 10.h),
            Text(
              'El cliente ya confirmó. Confirma tu parte para cerrar el trabajo.',
              style:
                  AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationRow({
    required IconData icon,
    required String label,
    required bool confirmed,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.blue.withValues(alpha: 0.6)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.blue),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18.sp,
          color: confirmed ? AppColors.success : AppColors.slateGrey,
        ),
        SizedBox(width: 4.w),
        Text(
          confirmed ? 'Confirmado' : 'Pendiente',
          style: AppTypography.caption.copyWith(
            color: confirmed ? AppColors.success : AppColors.slateGrey,
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(String estadoPostulacion, String nombreSolo) {
    // Postularse
    if (!widget.desdePostulaciones) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              Icons.send_outlined,
              'Postularme',
              AppColors.blue,
              AppColors.blue.withValues(alpha: 0.1),
              () async {
                try {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  if (userProvider.user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Debes iniciar sesión para postularte')),
                    );
                    return;
                  }
                  await JobService.apply(
                      widget.job['id'], userProvider.user!.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Postulación enviada correctamente')),
                  );
                  Navigator.of(context).pop();
                  widget.onPostulacionCambiada?.call();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al postularse: $e')),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              Icons.flag_outlined,
              'Reportar publicación',
              AppColors.error,
              AppColors.error.withValues(alpha: 0.1),
              () {
                final jobId = widget.job['id'];
                if (jobId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReportScreen(jobId: jobId)),
                  );
                }
              },
            ),
          ),
        ],
      );
    }

    // Trabajo aceptado y servicio ya completado → ver chat + calificación
    if (estadoPostulacion == 'accepted' && _serviceCompleted) {
      final userId =
          Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              Icons.chat_bubble_outline_rounded,
              'Ver chat',
              AppColors.blue,
              AppColors.blue.withValues(alpha: 0.1),
              () => _openChat(nombreSolo, readOnly: true),
            ),
          ),
          if (_serviceId != null && _ratedUserId != null) ...[
            SizedBox(height: 12.h),
            RatingSectionWidget(
              serviceId: _serviceId!,
              raterId: userId,
              ratedId: _ratedUserId!,
              ratedName: nombreSolo,
              hasRated: _hasRated,
              myScore: _myScore,
              onRated: () => setState(() {
                _hasRated = true;
                _myScore = 0; // se actualizará en el próximo _loadMyRating
                _loadMyRating();
              }),
            ),
          ],
        ],
      );
    }

    // Trabajo aceptado en curso
    if (estadoPostulacion == 'accepted') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              Icons.chat_bubble_outline_rounded,
              'Hablar con $nombreSolo',
              AppColors.blue,
              AppColors.blue.withValues(alpha: 0.1),
              () => _openChat(nombreSolo),
            ),
          ),
          if (!_workerHasConfirmed) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: _actionButton(
                Icons.check_circle_outline_rounded,
                'Marcar como terminado',
                AppColors.success,
                AppColors.success.withValues(alpha: 0.1),
                _markAsFinished,
              ),
            ),
          ],
          if (!_workerHasConfirmed && !_clientHasConfirmed) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: _actionButton(
                Icons.cancel_outlined,
                'Cancelar trabajo',
                AppColors.error,
                AppColors.error.withValues(alpha: 0.1),
                _cancelJob,
              ),
            ),
          ],
        ],
      );
    }

    // Postulación pendiente
    if (estadoPostulacion == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: _actionButton(
          Icons.chat_bubble_outline,
          'Hablar con $nombreSolo',
          AppColors.blue,
          AppColors.blue.withValues(alpha: 0.1),
          () => _openChat(nombreSolo),
        ),
      );
    }

    // Trabajo finalizado
    if (estadoPostulacion == 'finished') {
      return SizedBox(
        width: double.infinity,
        child: _actionButton(
          Icons.chat_bubble_outline_rounded,
          'Ver chat',
          AppColors.blue,
          AppColors.blue.withValues(alpha: 0.1),
          () => _openChat(nombreSolo, readOnly: true),
        ),
      );
    }

    // Rechazada / retirada
    if (estadoPostulacion.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        child: _actionButton(
          Icons.delete_outline,
          'Eliminar postulación',
          AppColors.error,
          AppColors.error.withValues(alpha: 0.1),
          () async {
            await JobService.deleteApplication(widget.postulacion?['id']);
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Postulación eliminada correctamente')),
            );
            widget.onPostulacionCambiada?.call();
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionButton(
    IconData icon,
    String text,
    Color textColor,
    Color bgColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp, color: textColor),
      label: Text(text, style: AppTypography.body.copyWith(color: textColor)),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: bgColor,
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _openChat(String nombreSolo, {bool readOnly = false}) {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          applicationId: widget.postulacion!['id'] as String,
          currentUserId: userId,
          otherPersonName: nombreSolo,
          readOnly: readOnly,
        ),
      ),
    );
  }

  Future<void> _markAsFinished() async {
    try {
      final result =
          await JobService.markAsFinished(widget.postulacion?['id']);
      if (!mounted) return;
      final completed = result['completed'] as bool? ?? false;
      if (completed) {
        // Opción 1: mostrar modal de calificación antes de salir
        final userId =
            Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
        if (_serviceId != null && _ratedUserId != null && userId.isNotEmpty) {
          await showRatingDialog(
            context: context,
            serviceId: _serviceId!,
            raterId: userId,
            ratedId: _ratedUserId!,
            ratedName: _nombreSolo,
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('¡Trabajo finalizado con éxito! Ambos confirmaron.')),
        );
        widget.onPostulacionCambiada?.call();
      } else {
        setState(() => _workerHasConfirmed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Confirmación enviada. Esperando que el cliente confirme también.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al confirmar: $e')));
    }
  }

  Future<void> _cancelJob() async {
    await JobService.cancelJob(widget.postulacion?['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trabajo cancelado')),
    );
    Navigator.of(context).pop();
    widget.onPostulacionCambiada?.call();
  }
}
