import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Skeleton loader animado con efecto shimmer «sweep».
///
/// Usado en listas y cards mientras los datos se están cargando.
///
/// ```dart
/// ShimmerLoader(width: double.infinity, height: 80, borderRadius: 12)
/// ```
class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            transform: _SlidingGradientTransform(_anim.value),
            colors: [
              AppColors.surfaceVariant,
              AppColors.surfaceVariant,
              AppColors.surfaceVariant.withValues(alpha: 0.55),
              AppColors.surfaceVariant,
              AppColors.surfaceVariant,
            ],
          ),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ---------------------------------------------------------------------------
// ShimmerCardList — conveniencia para listas de skeleton
// ---------------------------------------------------------------------------

/// Muestra [count] filas skeleton mientras carga una lista.
class ShimmerCardList extends StatelessWidget {
  const ShimmerCardList({super.key, this.count = 4, this.itemHeight = 80});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => ShimmerLoader(
        width: double.infinity,
        height: itemHeight,
        borderRadius: AppRadius.lg,
      ),
    );
  }
}
