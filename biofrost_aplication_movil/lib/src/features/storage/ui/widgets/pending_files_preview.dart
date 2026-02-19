import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/commands/upload_file_command.dart';

// Implementa RF-Storage-01: Preview de archivos seleccionados antes de subir.

/// Panel que muestra los archivos pendientes de subir y permite eliminarlos
/// de la selección antes de confirmar la subida.
class PendingFilesPreview extends StatelessWidget {
  const PendingFilesPreview({
    super.key,
    required this.commands,
    required this.onRemove,
    required this.onUpload,
    required this.onCancel,
    required this.isUploading,
    required this.uploadProgress,
    required this.progressLabel,
    required this.selectedFolder,
    required this.onFolderChanged,
  });

  final List<UploadFileCommand> commands;
  final void Function(int index) onRemove;
  final VoidCallback onUpload;
  final VoidCallback onCancel;
  final bool isUploading;
  final double uploadProgress;
  final String progressLabel;
  final String selectedFolder;
  final void Function(String folder) onFolderChanged;

  static const _folders = [
    ('projects', 'Proyectos', Icons.folder_special_rounded),
    ('showcase', 'Showcase', Icons.star_rounded),
    ('teams', 'Equipos', Icons.group_rounded),
    ('general', 'General', Icons.folder_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.upload_file_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${commands.length} archivo${commands.length != 1 ? 's' : ''} seleccionado${commands.length != 1 ? 's' : ''}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isUploading)
                GestureDetector(
                  onTap: onCancel,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Folder selector
          if (!isUploading) ...[
            Text(
              'Carpeta destino',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _folders
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: _FolderChip(
                          label: f.$2,
                          icon: f.$3,
                          isSelected: selectedFolder == f.$1,
                          onTap: () => onFolderChanged(f.$1),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // File list
          ...commands.asMap().entries.map(
            (entry) => _PendingFileItem(
              command: entry.value,
              index: entry.key,
              onRemove: isUploading ? null : () => onRemove(entry.key),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress bar (during upload)
          if (isUploading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subiendo...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  progressLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Action buttons
          if (!isUploading)
            BifrostButton(
              label:
                  'Subir ${commands.length} archivo${commands.length != 1 ? 's' : ''}',
              onPressed: onUpload,
              icon: Icons.cloud_upload_rounded,
              fullWidth: true,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending file item
// ---------------------------------------------------------------------------

class _PendingFileItem extends StatelessWidget {
  const _PendingFileItem({
    required this.command,
    required this.index,
    this.onRemove,
  });

  final UploadFileCommand command;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isImage = command.mimeType.startsWith('image/');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          // Thumbnail / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: isImage
                ? Image.file(
                    File(command.filePath),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _DefaultIcon(mimeType: command.mimeType),
                  )
                : _DefaultIcon(mimeType: command.mimeType),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.fileName,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatSize(command.sizeBytes),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Remove
          if (onRemove != null)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              onPressed: onRemove,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon({required this.mimeType});
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  (IconData, Color) _resolve() {
    if (mimeType.startsWith('image/')) {
      return (Icons.image_rounded, AppColors.info);
    }
    if (mimeType.startsWith('video/')) {
      return (Icons.videocam_rounded, AppColors.primary);
    }
    if (mimeType == 'application/pdf') {
      return (Icons.picture_as_pdf_rounded, AppColors.error);
    }
    return (Icons.insert_drive_file_rounded, AppColors.textMuted);
  }
}

// ---------------------------------------------------------------------------
// Folder chip
// ---------------------------------------------------------------------------

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
