import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/profile_notifier.dart';

// Implementa RF-Profile-01: Visualización y edición del perfil.
// Implementa RF-Profile-02: Upload de avatar desde cámara/galería.

/// Pantalla de perfil de usuario.
///
/// Flujo:
///   1. Vista de perfil — avatar, nombre, rol, datos académicos
///   2. Tap "Editar" → modo edición (nombre y apellidos)
///   3. Tap en avatar (en cualquier modo) → seleccionar imagen → upload
///   4. Tap "Guardar" → persiste en Firebase Auth + sesión local
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);

    // Snackbar reactivo para éxito / error
    ref.listen(profileProvider, (_, next) {
      if (!context.mounted) return;
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(_snackBar(next.successMessage!, AppColors.success));
        Future.microtask(
          () => ref.read(profileProvider.notifier).clearMessages(),
        );
      } else if (next.hasError && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(_snackBar(next.errorMessage!, AppColors.error));
        Future.microtask(
          () => ref.read(profileProvider.notifier).clearMessages(),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _ProfileAppBar(state: state),
      body: state.isLoading
          ? const _LoadingView()
          : state.user == null
          ? _NotFoundView(
              onRetry: () => ref.read(profileProvider.notifier).reload(),
            )
          : _ProfileBody(state: state),
    );
  }

  SnackBar _snackBar(String message, Color color) => SnackBar(
    content: Text(
      message,
      style: AppTextStyles.body.copyWith(color: Colors.white),
    ),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );
}

// ---------------------------------------------------------------------------
// AppBar personalizada
// ---------------------------------------------------------------------------

class _ProfileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _ProfileAppBar({required this.state});

  final ProfileState state;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileProvider.notifier);

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
        onPressed: () {
          if (state.isEditing) {
            notifier.cancelEdit();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            state.isEditing ? 'Editar perfil' : 'Mi perfil',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        if (!state.isLoading && state.user != null) ...[
          if (state.isEditing) ...[
            // Cancelar edición
            TextButton(
              onPressed: state.isSaving ? null : notifier.cancelEdit,
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: state.isSaving
                      ? AppColors.textDisabled
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            // Guardar
            TextButton(
              onPressed: state.isSaving ? null : notifier.saveProfile,
              child: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ] else ...[
            // Botón de editar
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: notifier.startEdit,
              tooltip: 'Editar perfil',
            ),
          ],
          const SizedBox(width: 4),
        ],
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body principal
// ---------------------------------------------------------------------------

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = state.user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Avatar + nombre + rol ─────────────────────────────────────
          _AvatarSection(state: state),
          const SizedBox(height: AppSpacing.xl),

          // ── Formulario de edición ────────────────────────────────────
          if (state.isEditing) ...[
            _EditForm(state: state),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Información del perfil ────────────────────────────────────
          Text(
            'Información',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(
            items: [
              _InfoItem(
                icon: Icons.email_outlined,
                label: 'Correo electrónico',
                value: user.email,
              ),
              _InfoItem(
                icon: Icons.badge_outlined,
                label: 'Rol',
                valuePadding: true,
                child: BifrostBadge.forRol(user.rol),
              ),
              if (user.matricula != null && user.matricula!.isNotEmpty)
                _InfoItem(
                  icon: Icons.numbers_rounded,
                  label: 'Matrícula',
                  value: user.matricula!,
                ),
              if (user.grupoId != null && user.grupoId!.isNotEmpty)
                _InfoItem(
                  icon: Icons.group_work_outlined,
                  label: 'Grupo',
                  value: user.grupoId!,
                ),
              if (user.carreraId != null && user.carreraId!.isNotEmpty)
                _InfoItem(
                  icon: Icons.school_outlined,
                  label: 'Carrera',
                  value: user.carreraId!,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Cerrar sesión ─────────────────────────────────────────────
          if (!state.isEditing) _LogoutButton(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sección de avatar
// ---------------------------------------------------------------------------

class _AvatarSection extends ConsumerWidget {
  const _AvatarSection({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = state.user!;
    final displayName = state.isEditing
        ? '${state.editNombre ?? user.nombre} '
              '${state.editApellidoPaterno ?? user.apellidoPaterno}'
        : user.nombreCompleto;

    return Column(
      children: [
        // Avatar con botón de cámara superpuesto
        Stack(
          alignment: Alignment.center,
          children: [
            // Halo de carga durante upload de avatar
            if (state.isSavingAvatar)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            else
              BifrostAvatar(
                name: user.nombreCompleto,
                imageUrl: user.fotoUrl,
                rol: user.rol,
                size: AvatarSize.xl,
                showRolDot: true,
              ),

            // Botón cámara (siempre visible para cambiar avatar)
            if (!state.isSavingAvatar)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickAvatar(context, ref),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Nombre
        Text(
          displayName,
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),

        // Badge de rol
        BifrostBadge.forRol(user.rol),
      ],
    );
  }

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final option = await _showAvatarSourceSheet(context);
    if (option == null || !context.mounted) return;

    final picker = ImagePicker();
    XFile? picked;
    if (option == _AvatarSource.camera) {
      picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
    } else {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    }

    if (picked == null || !context.mounted) return;

    final size = await File(picked.path).length();
    ref
        .read(profileProvider.notifier)
        .uploadAvatar(
          filePath: picked.path,
          fileName: picked.name,
          mimeType: lookupMimeType(picked.path) ?? 'image/jpeg',
          sizeBytes: size,
        );
  }

  Future<_AvatarSource?> _showAvatarSourceSheet(BuildContext context) {
    return showModalBottomSheet<_AvatarSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BifrostBottomSheet(
        title: 'Cambiar avatar',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BifrostListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
                title: 'Tomar foto',
                onTap: () => Navigator.of(context).pop(_AvatarSource.camera),
              ),
              BifrostListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                title: 'Elegir de galería',
                onTap: () => Navigator.of(context).pop(_AvatarSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AvatarSource { camera, gallery }

// ---------------------------------------------------------------------------
// Formulario de edición
// ---------------------------------------------------------------------------

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.state});

  final ProfileState state;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoPCtrl;
  late final TextEditingController _apellidoMCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.state.editNombre ?? '');
    _apellidoPCtrl = TextEditingController(
      text: widget.state.editApellidoPaterno ?? '',
    );
    _apellidoMCtrl = TextEditingController(
      text: widget.state.editApellidoMaterno ?? '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPCtrl.dispose();
    _apellidoMCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    ref
        .read(profileProvider.notifier)
        .updateField(
          nombre: _nombreCtrl.text,
          apellidoPaterno: _apellidoPCtrl.text,
          apellidoMaterno: _apellidoMCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editar nombre',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BifrostInput(
          controller: _nombreCtrl,
          label: 'Nombre(s)',
          prefixIcon: Icons.person_outline_rounded,
          enabled: !widget.state.isSaving,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _notify(),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        BifrostInput(
          controller: _apellidoPCtrl,
          label: 'Apellido paterno',
          prefixIcon: Icons.person_outline_rounded,
          enabled: !widget.state.isSaving,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _notify(),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        BifrostInput(
          controller: _apellidoMCtrl,
          label: 'Apellido materno',
          prefixIcon: Icons.person_outline_rounded,
          enabled: !widget.state.isSaving,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _notify(),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de información
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          final item = entry.value;
          return Column(
            children: [
              _InfoRow(item: item),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: AppSpacing.md + 38,
                  color: AppColors.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.valuePadding = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  final bool valuePadding;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(item.icon, color: AppColors.textSecondary, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                if (item.child != null)
                  Padding(padding: EdgeInsets.zero, child: item.child)
                else
                  Text(
                    item.value ?? '—',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Botón de logout
// ---------------------------------------------------------------------------

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BifrostButton(
      label: 'Cerrar sesión',
      variant: BifrostButtonVariant.outline,
      icon: Icons.logout_rounded,
      fullWidth: true,
      onPressed: () async {
        final confirmed = await BifrostModal.show(
          context,
          title: 'Cerrar sesión',
          message: '¿Seguro que deseas salir de tu cuenta?',
          confirmLabel: 'Cerrar sesión',
          isDanger: true,
          icon: Icons.logout_rounded,
        );
        if (confirmed == true && context.mounted) {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Not Found views
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BifrostEmptyState(
      icon: Icons.person_off_outlined,
      title: 'Perfil no disponible',
      message: 'No se pudo cargar tu perfil. Verifica tu conexión.',
      action: BifrostButton(
        label: 'Reintentar',
        variant: BifrostButtonVariant.primary,
        size: BifrostButtonSize.sm,
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
      ),
    );
  }
}
