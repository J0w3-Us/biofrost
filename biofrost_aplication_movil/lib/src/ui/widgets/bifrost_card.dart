import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

// ============================================================================
// BifrostCard
// ============================================================================

/// Contenedor de superficie con el estilo oscuro de Bifrost.
///
/// Variantes: normal (estática) e interactiva (efecto press).
///
/// Ejemplo:
/// ```dart
/// BifrostCard(
///   child: Text('Contenido'),
///   onTap: () => _open(),
/// )
/// ```
class BifrostCard extends StatelessWidget {
  const BifrostCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevated = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap == null) return container;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),
      child: container,
    );
  }
}

// ============================================================================
// BifrostCardHeader / BifrostCardContent / BifrostCardFooter
// ============================================================================

/// Encabezado de una [BifrostCard] con título y subtítulo opcionales.
class BifrostCardHeader extends StatelessWidget {
  const BifrostCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
        ],
      ],
    );
  }
}

/// Área de contenido principal de una card con padding estándar.
class BifrostCardContent extends StatelessWidget {
  const BifrostCardContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Pie de una card con acción secundaria.
class BifrostCardFooter extends StatelessWidget {
  const BifrostCardFooter({
    super.key,
    required this.child,
    this.showDivider = true,
  });

  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider) ...[
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
        ],
        child,
      ],
    );
  }
}
