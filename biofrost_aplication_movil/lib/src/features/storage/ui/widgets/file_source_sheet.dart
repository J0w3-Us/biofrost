import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/commands/upload_file_command.dart';

// Implementa RF-Storage-01: Selección del origen de archivos para subida.

/// Bottom sheet que permite al usuario elegir de dónde tomar los archivos.
/// Retorna una lista de [UploadFileCommand] listos para subir.
class FileSourceSheet extends StatelessWidget {
  const FileSourceSheet({super.key});

  // --------------------------------------------------------------------------
  // Static show helper
  // --------------------------------------------------------------------------

  static Future<List<UploadFileCommand>?> show(BuildContext context) {
    return showModalBottomSheet<List<UploadFileCommand>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FileSourceSheet(),
    );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BifrostBottomSheet(
      title: 'Seleccionar archivo',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: Icons.camera_alt_rounded,
              label: 'Cámara',
              description: 'Tomar una foto nueva',
              color: AppColors.info,
              onTap: () => _onCamera(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Galería',
              description: 'Seleccionar imágenes',
              color: AppColors.success,
              onTap: () => _onGallery(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: Icons.attach_file_rounded,
              label: 'Archivos',
              description: 'PDF, Word, ZIP y más',
              color: AppColors.warning,
              onTap: () => _onFiles(context),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Handlers
  // --------------------------------------------------------------------------

  Future<void> _onCamera(BuildContext context) async {
    Navigator.of(context).pop();
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo == null || !context.mounted) return;
    final commands = await _xFilesToCommands([photo]);
    if (context.mounted) Navigator.of(context).pop(commands);
  }

  Future<void> _onGallery(BuildContext context) async {
    Navigator.of(context).pop();
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty || !context.mounted) return;
    final commands = await _xFilesToCommands(images);
    if (context.mounted) Navigator.of(context).pop(commands);
  }

  Future<void> _onFiles(BuildContext context) async {
    Navigator.of(context).pop();
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (result == null || result.files.isEmpty || !context.mounted) return;
    final commands = result.files
        .where((f) => f.path != null)
        .map(
          (f) => UploadFileCommand(
            filePath: f.path!,
            fileName: f.name,
            mimeType: lookupMimeType(f.path!) ?? 'application/octet-stream',
            sizeBytes: f.size,
          ),
        )
        .toList();
    if (context.mounted) Navigator.of(context).pop(commands);
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  Future<List<UploadFileCommand>> _xFilesToCommands(List<XFile> files) async {
    final commands = <UploadFileCommand>[];
    for (final xf in files) {
      final file = File(xf.path);
      final size = await file.length();
      commands.add(
        UploadFileCommand(
          filePath: xf.path,
          fileName: xf.name,
          mimeType: lookupMimeType(xf.path) ?? 'image/jpeg',
          sizeBytes: size,
        ),
      );
    }
    return commands;
  }
}

// ---------------------------------------------------------------------------
// Tile interno del sheet
// ---------------------------------------------------------------------------

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
