import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

// ============================================================================
// Variants & Sizes
// ============================================================================

enum BifrostButtonVariant { primary, secondary, ghost, outline, danger }

enum BifrostButtonSize { sm, md, lg }

// ============================================================================
// BifrostButton
// ============================================================================

/// Botón principal del UI Kit de Bifrost.
///
/// Soporta variantes: [primary], [secondary], [ghost], [outline], [danger].
/// Soporta tamaños: [sm], [md], [lg].
/// Muestra spinner cuando [isLoading] es true.
///
/// Ejemplo:
/// ```dart
/// BifrostButton(
///   label: 'Guardar',
///   onPressed: _save,
///   isLoading: state.isLoading,
/// )
/// ```
class BifrostButton extends StatelessWidget {
  const BifrostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BifrostButtonVariant.primary,
    this.size = BifrostButtonSize.md,
    this.isLoading = false,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final BifrostButtonVariant variant;
  final BifrostButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(variant);
    final dims = _dimsFor(size);
    final textStyle = _textStyleFor(size);

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: dims.iconSize,
            height: dims.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: style.foreground,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null && iconPosition == IconPosition.left) ...[
          Icon(icon, size: dims.iconSize, color: style.foreground),
          const SizedBox(width: 8),
        ],
        Text(label, style: textStyle.copyWith(color: style.foreground)),
        if (!isLoading &&
            icon != null &&
            iconPosition == IconPosition.right) ...[
          const SizedBox(width: 8),
          Icon(icon, size: dims.iconSize, color: style.foreground),
        ],
      ],
    );

    final button = AnimatedOpacity(
      opacity: onPressed == null && !isLoading ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        height: dims.height,
        width: fullWidth ? double.infinity : null,
        child: _buildButton(style, dims, content),
      ),
    );

    return button;
  }

  Widget _buildButton(_ButtonStyle style, _ButtonDims dims, Widget content) {
    if (variant == BifrostButtonVariant.outline ||
        variant == BifrostButtonVariant.ghost) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: style.foreground,
          side: BorderSide(
            color: variant == BifrostButtonVariant.outline
                ? style.border!
                : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
          ),
          padding: EdgeInsets.symmetric(horizontal: dims.padH),
          elevation: 0,
          overlayColor: style.foreground.withValues(alpha: 0.08),
        ),
        child: content,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: style.background,
        disabledBackgroundColor: style.background.withValues(alpha: 0.55),
        foregroundColor: style.foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
        ),
        padding: EdgeInsets.symmetric(horizontal: dims.padH),
        elevation: 0,
        overlayColor: AppColors.textPrimary.withValues(alpha: 0.08),
      ),
      child: content,
    );
  }

  // ── Style helpers ──────────────────────────────────────────────────────────

  static _ButtonStyle _styleFor(BifrostButtonVariant v) => switch (v) {
    BifrostButtonVariant.primary => _ButtonStyle(
      background: AppColors.primary,
      foreground: Colors.white,
    ),
    BifrostButtonVariant.secondary => _ButtonStyle(
      background: AppColors.surfaceVariant,
      foreground: AppColors.textPrimary,
    ),
    BifrostButtonVariant.ghost => _ButtonStyle(
      background: Colors.transparent,
      foreground: AppColors.textSecondary,
    ),
    BifrostButtonVariant.outline => _ButtonStyle(
      background: Colors.transparent,
      foreground: AppColors.primary,
      border: AppColors.borderFocus,
    ),
    BifrostButtonVariant.danger => _ButtonStyle(
      background: AppColors.errorBg,
      foreground: AppColors.error,
    ),
  };

  static _ButtonDims _dimsFor(BifrostButtonSize s) => switch (s) {
    BifrostButtonSize.sm => _ButtonDims(height: 38, padH: 14, iconSize: 16),
    BifrostButtonSize.md => _ButtonDims(height: 48, padH: 18, iconSize: 18),
    BifrostButtonSize.lg => _ButtonDims(height: 56, padH: 24, iconSize: 20),
  };

  static TextStyle _textStyleFor(BifrostButtonSize s) => switch (s) {
    BifrostButtonSize.sm => AppTextStyles.buttonSmall,
    BifrostButtonSize.md => AppTextStyles.button,
    BifrostButtonSize.lg => AppTextStyles.buttonLarge,
  };
}

// ── Internal data classes ──────────────────────────────────────────────────

class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.foreground,
    this.border,
  });
  final Color background;
  final Color foreground;
  final Color? border;
}

class _ButtonDims {
  const _ButtonDims({
    required this.height,
    required this.padH,
    required this.iconSize,
  });
  final double height;
  final double padH;
  final double iconSize;
}

// ── IconPosition ─────────────────────────────────────────────────────────────

enum IconPosition { left, right }
