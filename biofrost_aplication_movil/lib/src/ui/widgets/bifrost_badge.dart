import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_text_styles.dart';

// ============================================================================
// Variant & Size
// ============================================================================

enum BifrostBadgeVariant {
  neutral,
  success,
  warning,
  error,
  info,
  primary,
  dark,
}

enum BifrostBadgeSize { sm, md, lg }

// ============================================================================
// BifrostBadge
// ============================================================================

/// Etiqueta de estado o categoría con variantes semánticas y de rol.
///
/// Ejemplo:
/// ```dart
/// BifrostBadge(label: 'Alumno', variant: BifrostBadgeVariant.info)
/// BifrostBadge.forRol('Docente')
/// BifrostBadge.status('Activo')
/// ```
class BifrostBadge extends StatelessWidget {
  const BifrostBadge({
    super.key,
    required this.label,
    this.variant = BifrostBadgeVariant.neutral,
    this.size = BifrostBadgeSize.md,
    this.icon,
    this.dot = false,
  });

  final String label;
  final BifrostBadgeVariant variant;
  final BifrostBadgeSize size;
  final IconData? icon;
  final bool dot;

  // ── Convenience constructors ──────────────────────────────────────────────

  /// Badge de rol con color automático.
  factory BifrostBadge.forRol(
    String rol, {
    BifrostBadgeSize size = BifrostBadgeSize.md,
  }) {
    final variant = switch (rol) {
      'Alumno' => BifrostBadgeVariant.info,
      'Docente' => BifrostBadgeVariant.success,
      'Admin' => BifrostBadgeVariant.error,
      _ => BifrostBadgeVariant.warning, // Invitado
    };
    final icon = switch (rol) {
      'Alumno' => Icons.school_outlined,
      'Docente' => Icons.badge_outlined,
      'Admin' => Icons.admin_panel_settings_outlined,
      _ => Icons.person_outline,
    };
    return BifrostBadge(label: rol, variant: variant, size: size, icon: icon);
  }

  /// Badge de estado de proyecto.
  factory BifrostBadge.status(
    String status, {
    BifrostBadgeSize size = BifrostBadgeSize.md,
  }) {
    final (variant, icon) = switch (status.toLowerCase()) {
      'activo' ||
      'publicado' => (BifrostBadgeVariant.success, Icons.check_circle_outline),
      'borrador' => (BifrostBadgeVariant.neutral, Icons.edit_outlined),
      'en revisión' ||
      'pendiente' => (BifrostBadgeVariant.warning, Icons.schedule_outlined),
      'archivado' ||
      'inactivo' => (BifrostBadgeVariant.dark, Icons.archive_outlined),
      'rechazado' => (BifrostBadgeVariant.error, Icons.cancel_outlined),
      _ => (BifrostBadgeVariant.neutral, null),
    };
    return BifrostBadge(
      label: status,
      variant: variant,
      size: size,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(variant);
    final dims = _dimsFor(size);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dims.padH, vertical: dims.padV),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, color: colors.foreground, size: dims.iconSize),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: colors.foreground,
              fontSize: dims.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static _BadgeColors _colorsFor(BifrostBadgeVariant v) => switch (v) {
    BifrostBadgeVariant.neutral => _BadgeColors(
      background: const Color(0xFF1F2937),
      foreground: const Color(0xFF9CA3AF),
      border: const Color(0xFF374151),
    ),
    BifrostBadgeVariant.success => _BadgeColors(
      background: AppColors.successBg,
      foreground: AppColors.success,
      border: AppColors.success.withValues(alpha: 0.35),
    ),
    BifrostBadgeVariant.warning => _BadgeColors(
      background: AppColors.warningBg,
      foreground: AppColors.warning,
      border: AppColors.warning.withValues(alpha: 0.35),
    ),
    BifrostBadgeVariant.error => _BadgeColors(
      background: AppColors.errorBg,
      foreground: AppColors.error,
      border: AppColors.error.withValues(alpha: 0.35),
    ),
    BifrostBadgeVariant.info => _BadgeColors(
      background: AppColors.infoBg,
      foreground: AppColors.info,
      border: AppColors.info.withValues(alpha: 0.35),
    ),
    BifrostBadgeVariant.primary => _BadgeColors(
      background: AppColors.primaryMuted,
      foreground: Colors.white,
      border: AppColors.primary.withValues(alpha: 0.4),
    ),
    BifrostBadgeVariant.dark => _BadgeColors(
      background: const Color(0xFF111827),
      foreground: const Color(0xFF6B7280),
      border: const Color(0xFF1F2937),
    ),
  };

  static _BadgeDims _dimsFor(BifrostBadgeSize s) => switch (s) {
    BifrostBadgeSize.sm => _BadgeDims(
      padH: 7,
      padV: 2,
      fontSize: 10,
      iconSize: 11,
    ),
    BifrostBadgeSize.md => _BadgeDims(
      padH: 10,
      padV: 4,
      fontSize: 11.5,
      iconSize: 13,
    ),
    BifrostBadgeSize.lg => _BadgeDims(
      padH: 12,
      padV: 5,
      fontSize: 13,
      iconSize: 15,
    ),
  };
}

// ── Internal data ──────────────────────────────────────────────────────────

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
  final Color background;
  final Color foreground;
  final Color border;
}

class _BadgeDims {
  const _BadgeDims({
    required this.padH,
    required this.padV,
    required this.fontSize,
    required this.iconSize,
  });
  final double padH;
  final double padV;
  final double fontSize;
  final double iconSize;
}
