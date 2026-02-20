import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Card con efecto glassmorphism: fondo semi-transparente + blur.
///
/// Úsala sobre fondos con gradiente o imágenes para lograr el efecto
/// "vidrio esmerilado" característico del nuevo diseño de Bifrost.
///
/// ```dart
/// GlassCard(
///   child: Text('Hola'),
///   borderRadius: 20,
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.blur = 12.0,
    this.opacity = 0.08,
    this.borderOpacity = 0.18,
    this.onTap,
    this.elevation = false,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;

  /// Opacidad del fondo blanco (0.0 – 1.0). A mayor valor más opaco.
  final double opacity;

  /// Opacidad del borde (0.0 – 1.0).
  final double borderOpacity;

  final VoidCallback? onTap;

  /// Añade sombra sutil debajo de la card.
  final bool elevation;

  /// Color del glow inferior (ej `AppColors.primary`). Null = sin glow.
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.2,
            ),
            boxShadow: [
              if (elevation)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              if (glowColor != null)
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          child: card,
        ),
      );
    }

    return Container(margin: margin, child: card);
  }
}
