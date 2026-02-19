import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/read/uploaded_file_read_model.dart';

// Implementa RF-Storage-01: Visualización de archivos subidos.

/// Tarjeta que muestra un archivo subido al servidor.
/// Permite copiar la URL y disparar la eliminación.
class UploadedFileCard extends StatelessWidget {
  const UploadedFileCard({
    super.key,
    required this.file,
    required this.onDelete,
  });

  final UploadedFile file;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview / Icon area
          _FilePreview(file: file),

          // Metadata
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    BifrostBadge(
                      label: file.folder,
                      variant: BifrostBadgeVariant.primary,
                      size: BifrostBadgeSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      file.formattedSize,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copiar URL',
                    onTap: () => _copyUrl(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar',
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: file.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'URL copiada',
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview del archivo
// ---------------------------------------------------------------------------

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.file});

  final UploadedFile file;

  @override
  Widget build(BuildContext context) {
    if (file.isImage && file.url.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.md),
          topRight: Radius.circular(AppRadius.md),
        ),
        child: Image.network(
          file.url,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PlaceholderIcon(file: file),
        ),
      );
    }
    return _PlaceholderIcon(file: file);
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.file});

  final UploadedFile file;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(file);
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.md),
          topRight: Radius.circular(AppRadius.md),
        ),
      ),
      child: Center(child: Icon(icon, color: color, size: 40)),
    );
  }

  (IconData, Color) _iconFor(UploadedFile file) {
    if (file.isImage) return (Icons.image_rounded, AppColors.info);
    if (file.isVideo) return (Icons.videocam_rounded, AppColors.primary);
    if (file.isPdf) return (Icons.picture_as_pdf_rounded, AppColors.error);
    if (file.isDocument) return (Icons.description_rounded, AppColors.warning);
    return (Icons.insert_drive_file_rounded, AppColors.textMuted);
  }
}

// ---------------------------------------------------------------------------
// Botón de acción reutilizable
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption.copyWith(color: c)),
            ],
          ),
        ),
      ),
    );
  }
}
