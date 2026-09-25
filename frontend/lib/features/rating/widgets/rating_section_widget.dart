import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/rating/logic/rating_service.dart';
import 'package:nodo/features/rating/widgets/star_rating_widget.dart';

/// Sección de calificación que aparece dentro del detalle del servicio
/// cuando el trabajo ya está completado.
///
/// - Si [hasRated] es true muestra la calificación enviada ([myScore]).
/// - Si no, permite seleccionar estrellas y enviar.
class RatingSectionWidget extends StatefulWidget {
  final String serviceId;
  final String raterId;
  final String ratedId;
  final String ratedName;
  final bool hasRated;
  final int myScore;
  final VoidCallback? onRated;

  const RatingSectionWidget({
    super.key,
    required this.serviceId,
    required this.raterId,
    required this.ratedId,
    required this.ratedName,
    required this.hasRated,
    required this.myScore,
    this.onRated,
  });

  @override
  State<RatingSectionWidget> createState() => _RatingSectionWidgetState();
}

class _RatingSectionWidgetState extends State<RatingSectionWidget> {
  int _selectedScore = 0;
  bool _sending = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedScore == 0 || _sending) return;
    setState(() => _sending = true);
    try {
      await RatingService.submitRating(
        serviceId: widget.serviceId,
        raterId: widget.raterId,
        ratedId: widget.ratedId,
        score: _selectedScore,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      widget.onRated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calificación enviada. ¡Gracias!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
      ),
      child: widget.hasRated ? _buildDone() : _buildPending(),
    );
  }

  // — Ya calificado ────────────────────────────────────────────────────────

  Widget _buildDone() {
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded,
            color: AppColors.success, size: 18.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calificaste a ${widget.ratedName}',
                style: AppTypography.label.copyWith(color: AppColors.blue),
              ),
              SizedBox(height: 4.h),
              StarRatingWidget(value: widget.myScore, size: 18.r),
            ],
          ),
        ),
      ],
    );
  }

  // — Pendiente de calificar ───────────────────────────────────────────────

  Widget _buildPending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline_rounded,
                color: AppColors.orange, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Califica a ${widget.ratedName}',
              style: AppTypography.label.copyWith(color: AppColors.blue),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Center(
          child: StarRatingWidget(
            value: _selectedScore,
            interactive: true,
            size: 30.r,
            onChanged: (v) => setState(() => _selectedScore = v),
          ),
        ),
        if (_selectedScore > 0) ...[
          SizedBox(height: 4.h),
          Center(
            child: Text(
              _labelForScore(_selectedScore),
              style: AppTypography.caption
                  .copyWith(color: AppColors.orange),
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Comentario opcional…',
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Enviar calificación',
                      style:
                          AppTypography.body.copyWith(color: AppColors.white),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

String _labelForScore(int score) {
  return switch (score) {
    1 => 'Muy malo',
    2 => 'Malo',
    3 => 'Regular',
    4 => 'Bueno',
    5 => 'Excelente',
    _ => '',
  };
}
