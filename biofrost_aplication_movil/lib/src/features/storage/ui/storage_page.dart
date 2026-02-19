import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/storage_notifier.dart';
import '../data/models/read/uploaded_file_read_model.dart';
import 'widgets/file_source_sheet.dart';
import 'widgets/pending_files_preview.dart';
import 'widgets/uploaded_file_card.dart';

// Implementa RF-Storage-01: Subida de archivos desde dispositivo al servidor.
// Implementa RF-Storage-02: Eliminación de archivos con confirmación.

/// Pantalla principal del módulo de Storage.
///
/// Flujo de usuario:
///   1. Ver archivos subidos (sesión actual)
///   2. FAB → elegir origen (cámara, galería, archivos)
///   3. Preview + selección de carpeta → Subir
///   4. Ver progreso → archivos aparecen en la grilla
///   5. Mantener presionado → confirmar eliminación
class StoragePage extends ConsumerStatefulWidget {
  const StoragePage({super.key});

  static const routeName = '/storage';

  @override
  ConsumerState<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends ConsumerState<StoragePage> {
  @override
  Widget build(BuildContext context) {
    final storageState = ref.watch(storageProvider);
    final user = ref.watch(authProvider).user;

    // Escuchar errores y mostrar snackbar
    ref.listen(storageProvider, (prev, next) {
      if (next.hasError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ref.read(storageProvider.notifier).clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user?.nombre),
      floatingActionButton: _buildFab(storageState.hasPending),
      body: Column(
        children: [
          // Panel de archivos pendientes (si existen)
          if (storageState.hasPending || storageState.isUploading)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                0,
              ),
              child: PendingFilesPreview(
                commands: storageState.pendingCommands,
                onRemove: (index) {
                  final updated = List.of(storageState.pendingCommands)
                    ..removeAt(index);
                  ref.read(storageProvider.notifier).setPending(updated);
                },
                onUpload: () => ref.read(storageProvider.notifier).uploadAll(),
                onCancel: () =>
                    ref.read(storageProvider.notifier).clearPending(),
                isUploading: storageState.isUploading,
                uploadProgress: storageState.uploadProgress,
                progressLabel: storageState.progressLabel,
                selectedFolder: storageState.selectedFolder,
                onFolderChanged: (f) =>
                    ref.read(storageProvider.notifier).setFolder(f),
              ),
            ),

          // Sección de archivos subidos
          Expanded(
            child: storageState.hasFiles
                ? _FileGrid(files: storageState.uploadedFiles)
                : _EmptyState(hasPending: storageState.hasPending),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // AppBar
  // --------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, String? nombre) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Archivos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // FAB
  // --------------------------------------------------------------------------

  Widget _buildFab(bool hasPending) {
    if (hasPending) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: _openFilePicker,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Subir archivo',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // File picker flow
  // --------------------------------------------------------------------------

  Future<void> _openFilePicker() async {
    final commands = await FileSourceSheet.show(context);
    if (commands == null || commands.isEmpty || !mounted) return;
    ref.read(storageProvider.notifier).setPending(commands);
  }
}

// ---------------------------------------------------------------------------
// Grilla de archivos subidos
// ---------------------------------------------------------------------------

class _FileGrid extends ConsumerWidget {
  const _FileGrid({required this.files});

  final List<UploadedFile> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.md,
            AppSpacing.pagePadding,
            100, // espacio para el FAB
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final file = files[index];
              return UploadedFileCard(
                file: file,
                onDelete: () => _confirmDelete(context, ref, file),
              );
            }, childCount: files.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.72,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UploadedFile file,
  ) async {
    final confirmed = await BifrostModal.show(
      context,
      title: 'Eliminar archivo',
      message:
          '¿Eliminar "${file.fileName}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDanger: true,
    );
    if (confirmed == true && context.mounted) {
      ref.read(storageProvider.notifier).deleteFile(file);
    }
  }
}

// ---------------------------------------------------------------------------
// Estado vacío
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasPending});

  final bool hasPending;

  @override
  Widget build(BuildContext context) {
    return BifrostEmptyState(
      icon: Icons.cloud_upload_outlined,
      title: hasPending ? 'Archivos listos para subir' : 'Sin archivos subidos',
      message: hasPending
          ? 'Verifica la lista arriba y toca "Subir".'
          : 'Toca el botón + para subir fotos, documentos o videos.',
    );
  }
}
