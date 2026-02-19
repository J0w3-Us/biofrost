import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import 'bifrost_button.dart';

// ============================================================================
// BifrostModal
// ============================================================================

/// Modal de confirmación / acción con el estilo oscuro de Bifrost.
///
/// Mostrar con [BifrostModal.show]:
/// ```dart
/// final confirmed = await BifrostModal.show(
///   context,
///   title: '¿Eliminar grupo?',
///   message: 'Esta acción no se puede deshacer.',
///   confirmLabel: 'Eliminar',
///   isDanger: true,
/// );
/// if (confirmed == true) { /* ... */ }
/// ```
class BifrostModal extends StatelessWidget {
  const BifrostModal({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDanger = false,
    this.isLoading = false,
    this.icon,
  });

  final String title;
  final String? message;
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final bool isLoading;
  final IconData? icon;

  // ── Static show helper ─────────────────────────────────────────────────────

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDanger = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (_) => BifrostModal(
        title: title,
        message: message,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Ícono ──────────────────────────────────────────────────────
            if (icon != null) ...[
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDanger
                        ? AppColors.errorBg
                        : AppColors.primaryMuted.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    icon,
                    color: isDanger ? AppColors.error : AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Título ─────────────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3,
            ),

            // ── Mensaje ────────────────────────────────────────────────────
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            // ── Contenido custom ───────────────────────────────────────────
            if (content != null) ...[const SizedBox(height: 16), content!],

            const SizedBox(height: 24),

            // ── Acciones ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: BifrostButton(
                    label: cancelLabel,
                    variant: BifrostButtonVariant.secondary,
                    size: BifrostButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BifrostButton(
                    label: confirmLabel,
                    variant: isDanger
                        ? BifrostButtonVariant.danger
                        : BifrostButtonVariant.primary,
                    size: BifrostButtonSize.md,
                    isLoading: isLoading,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BifrostBottomSheet
// ============================================================================

/// Bottom sheet modal con handle y título estandarizados.
///
/// ```dart
/// BifrostBottomSheet.show(
///   context,
///   title: 'Opciones',
///   child: Column(children: [...]),
/// );
/// ```
class BifrostBottomSheet extends StatelessWidget {
  const BifrostBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.showHandle = true,
  });

  final String title;
  final Widget child;
  final bool showHandle;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    bool showHandle = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (_) => BifrostBottomSheet(
        title: title,
        showHandle: showHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          if (showHandle) ...[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ],

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(title, style: AppTextStyles.heading3),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Contenido
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
