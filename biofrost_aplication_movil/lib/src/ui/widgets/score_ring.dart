import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_text_styles.dart';

/// Anillo circular que visualiza una calificación numérica (0-100).
///
/// - Score >= 80 → verde
/// - Score >= 60 → amarillo
/// - Score <  60 → rojo
///
/// ```dart
/// ScoreRing(score: 87, size: 64)
/// ```
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 56,
    this.strokeWidth = 5.0,
    this.showLabel = true,
  });

  final double score;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: strokeWidth,
            backgroundColor: _color.withValues(alpha: 0.15),
            color: _color,
            strokeCap: StrokeCap.round,
          ),
          if (showLabel)
            Center(
              child: Text(
                score.toStringAsFixed(0),
                style: AppTextStyles.labelLarge.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.26,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge compacto de score en línea (sin anillo, solo texto con color).
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});

  final double score;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${score.toStringAsFixed(0)} pts',
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
