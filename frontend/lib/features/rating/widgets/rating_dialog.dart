import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nodo/core/theme/app_theme.dart';
import 'package:nodo/features/rating/logic/rating_service.dart';
import 'package:nodo/features/rating/widgets/star_rating_widget.dart';

/// Muestra el diálogo de calificación y devuelve `true` si el usuario envió
/// la calificación, `false` si la omitió.
Future<bool> showRatingDialog({
  required BuildContext context,
  required String serviceId,
  required String raterId,
  required String ratedId,
  required String ratedName,
}) async {
  bool submitted = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      int selectedScore = 0;
      bool sending = false;
      final commentController = TextEditingController();

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono superior
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: AppColors.orange,
                    size: 30.r,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  '¡Trabajo completado!',
                  style: AppTypography.subtitle.copyWith(color: AppColors.blue),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Califica tu experiencia con $ratedName',
                  style: AppTypography.body.copyWith(color: AppColors.slateGrey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                StarRatingWidget(
                  value: selectedScore,
                  interactive: true,
                  size: 36.r,
                  onChanged: (v) => setDialogState(() => selectedScore = v),
                ),
                SizedBox(height: 6.h),
                AnimatedOpacity(
                  opacity: selectedScore > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _labelForScore(selectedScore),
                    style: AppTypography.caption.copyWith(color: AppColors.orange),
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Agrega un comentario (opcional)',
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
            actionsPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            actions: [
              TextButton(
                onPressed:
                    sending ? null : () => Navigator.of(ctx).pop(),
                child: Text(
                  'Omitir',
                  style: AppTypography.body
                      .copyWith(color: AppColors.slateGrey),
                ),
              ),
              ElevatedButton(
                onPressed: (selectedScore == 0 || sending)
                    ? null
                    : () async {
                        setDialogState(() => sending = true);
                        try {
                          await RatingService.submitRating(
                            serviceId: serviceId,
                            raterId: raterId,
                            ratedId: ratedId,
                            score: selectedScore,
                            comment: commentController.text.trim(),
                          );
                          submitted = true;
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (e) {
                          setDialogState(() => sending = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text('Error al enviar: $e')),
                            );
                          }
                        }
                      },
                child: sending
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Enviar'),
              ),
            ],
          );
        },
      );
    },
  );

  return submitted;
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
