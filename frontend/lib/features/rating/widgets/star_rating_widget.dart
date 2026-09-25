import 'package:flutter/material.dart';
import 'package:nodo/core/theme/app_theme.dart';

/// Fila de 5 estrellas. En modo interactivo llama [onChanged] al tocar.
class StarRatingWidget extends StatelessWidget {
  final int value;
  final bool interactive;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRatingWidget({
    super.key,
    required this.value,
    this.interactive = false,
    this.size = 32,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? AppColors.orange : AppColors.slateGrey,
          size: size,
        );
        if (!interactive) return star;
        return GestureDetector(
          onTap: () => onChanged?.call(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }
}
