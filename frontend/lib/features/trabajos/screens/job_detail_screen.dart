import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/chat/screens/chat_1.dart';
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
  int _currentPage = 0;
  bool _isApplying = false;

  List<String> get _images {
    final raw = widget.job['images'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  String get _estadoPostulacion =>
      widget.postulacion?['status']?.toString() ?? '';

  String get _nombreCliente {
    final raw = widget.job['user']?.toString() ?? 'Cliente';
    return raw.contains(':') ? raw.split(':').last.trim() : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: _buildBody()),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final images = _images;
    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      backgroundColor: AppColors.blue,
      leading: Padding(
        padding: EdgeInsets.all(6.r),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 16.r),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 12.w, top: 6.h, bottom: 6.h),
          child: _ReportButton(jobId: widget.job['id']),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isNotEmpty)
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _NetworkImage(url: images[i]),
              )
            else
              const _ImagePlaceholder(),
            // gradient overlay so back button stays readable
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12.h,
                left: 0,
                right: 0,
                child: _PageDots(count: images.length, current: _currentPage),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final titulo = widget.job['title'] ?? 'Sin título';
    final descripcion = widget.job['description'] ?? '';
    final ubicacion = widget.job['location'] ?? '';
    final presupuesto = widget.job['price'] ?? '';
    final tiempo = widget.job['time'] ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + presupuesto
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: AppTypography.title.copyWith(
                    color: AppColors.blue,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              if (presupuesto.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    presupuesto,
                    style: AppTypography.body.copyWith(
                      color: AppColors.orange,
                      fontFamily: 'GothamBold',
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 16.h),

          // Info chips
          if (ubicacion.isNotEmpty)
            _InfoRow(Icons.location_on_outlined, ubicacion),
          if (tiempo.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _InfoRow(Icons.access_time_rounded, tiempo,
                color: Colors.redAccent.withValues(alpha: 0.85)),
          ],

          SizedBox(height: 20.h),

          // Descripción
          if (descripcion.isNotEmpty) ...[
            Text(
              'Descripción',
              style: AppTypography.body
                  .copyWith(color: AppColors.blue, fontFamily: 'GothamMedium'),
            ),
            SizedBox(height: 6.h),
            Text(
              descripcion,
              style: AppTypography.body
                  .copyWith(color: AppColors.slateGrey, height: 1.5),
            ),
            SizedBox(height: 20.h),
          ],

          const Divider(height: 1),
          SizedBox(height: 20.h),

          // Cliente
          Text(
            'Publicado por',
            style: AppTypography.body
                .copyWith(color: AppColors.blue, fontFamily: 'GothamMedium'),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Image.asset(
                    'assets/icons/iconNodoBlue.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nombreCliente,
                    style: AppTypography.body.copyWith(
                        color: AppColors.blue, fontFamily: 'GothamMedium'),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final showPostular = !widget.desdePostulaciones;
    final showHablar = _estadoPostulacion != 'finished';
    final showAceptar =
        widget.desdePostulaciones && _estadoPostulacion == 'pending';
    final showTerminado =
        widget.desdePostulaciones && _estadoPostulacion == 'accepted';
    final showEliminar = widget.desdePostulaciones &&
        _estadoPostulacion != 'accepted' &&
        _estadoPostulacion != 'finished';

    return Container(
      padding: EdgeInsets.fromLTRB(
          16.w, 12.h, 16.w, MediaQuery.of(context).padding.bottom + 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
              color: AppColors.slateGrey.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPostular)
            _ActionButton(
              label: _isApplying ? 'Enviando…' : 'Postularme',
              icon: Icons.send_rounded,
              color: AppColors.blue,
              isLoading: _isApplying,
              onTap: _postular,
            ),
          if (showHablar) ...[
            if (showPostular) SizedBox(height: 8.h),
            _ActionButton(
              label: 'Hablar con $_nombreCliente',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.slateGrey,
              outlined: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
          ],
          if (showAceptar) ...[
            _ActionButton(
              label: 'Aceptar trabajo',
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green.shade600,
              onTap: _aceptar,
            ),
            SizedBox(height: 8.h),
            _ActionButton(
              label: 'Hablar con $_nombreCliente',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.slateGrey,
              outlined: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
          ],
          if (showTerminado) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Trabajo terminado',
                    icon: Icons.task_alt_rounded,
                    color: AppColors.blue,
                    onTap: _marcarTerminado,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _ActionButton(
                    label: 'Cancelar',
                    icon: Icons.cancel_outlined,
                    color: Colors.redAccent,
                    onTap: _cancelar,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _ActionButton(
              label: 'Hablar con $_nombreCliente',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.slateGrey,
              outlined: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
          ],
          if (showEliminar) ...[
            _ActionButton(
              label: 'Eliminar postulación',
              icon: Icons.delete_outline_rounded,
              color: Colors.redAccent,
              outlined: true,
              onTap: _eliminarPostulacion,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _postular() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      _snack('Debes iniciar sesión para postularte');
      return;
    }
    setState(() => _isApplying = true);
    try {
      await JobService.apply(widget.job['id'], userProvider.user!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPostulacionCambiada?.call();
    } catch (e) {
      if (!mounted) return;
      _snack('Error al postularse: $e');
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _aceptar() async {
    try {
      await JobService.acceptApplication(widget.postulacion?['id'], 'accepted');
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack('¡Has aceptado el trabajo exitosamente!');
      widget.onPostulacionCambiada?.call();
    } catch (e) {
      if (!mounted) return;
      _snack('Error al aceptar postulación: $e');
    }
  }

  Future<void> _marcarTerminado() async {
    await JobService.markAsFinished(widget.postulacion?['id']);
    if (!mounted) return;
    _snack('Notificación enviada al cliente');
    Navigator.of(context).pop();
    widget.onPostulacionCambiada?.call();
  }

  Future<void> _cancelar() async {
    await JobService.cancelJob(widget.postulacion?['id']);
    if (!mounted) return;
    _snack('Trabajo cancelado');
    Navigator.of(context).pop();
    widget.onPostulacionCambiada?.call();
  }

  Future<void> _eliminarPostulacion() async {
    await JobService.deleteApplication(widget.postulacion?['id']);
    if (!mounted) return;
    Navigator.of(context).pop();
    _snack('Postulación eliminada correctamente');
    widget.onPostulacionCambiada?.call();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.slateGrey;
    return Row(
      children: [
        Icon(icon, size: 14.r, color: c),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(text,
              style: AppTypography.caption.copyWith(color: c),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  const _NetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const _ImagePlaceholder(loading: true),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool loading;
  const _ImagePlaceholder({this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue.withValues(alpha: 0.06),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Icon(
                Icons.work_outline_rounded,
                size: 52.r,
                color: AppColors.blue.withValues(alpha: 0.25),
              ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: i == current ? 16.w : 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: i == current
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final dynamic jobId;
  const _ReportButton({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (jobId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportScreen(jobId: jobId)),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, color: AppColors.white, size: 14.r),
            SizedBox(width: 4.w),
            Text('Reportar',
                style: AppTypography.caption.copyWith(
                    color: AppColors.white, fontFamily: 'GothamMedium')),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16.r,
            height: 16.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? color : AppColors.white,
            ),
          )
        else
          Icon(icon, size: 16.r, color: outlined ? color : AppColors.white),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: outlined ? color : AppColors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: content,
            ),
    );
  }
}
