import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:biofrost/features/auth/domain/models/user_read_model.dart';
import 'package:biofrost/features/evaluations/domain/models/evaluation_read_model.dart';
import 'package:biofrost/features/showcase/domain/models/project_read_model.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/utils/sanitize.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/core/providers/theme_provider.dart';
import 'package:biofrost/features/profile/providers/profile_projects_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';
import 'package:biofrost/features/showcase/providers/projects_provider.dart';

/// Pantalla de perfil del Docente.
///
/// Solo accesible con [AuthStateAuthenticated] y rol Docente.
/// Muestra: datos personales, asignaciones y botón de logout.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // RF-BNB: Perfil tab seleccionado (spec §1 Barra de Navegación Inferior)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              const Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _ProfileNavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  isSelected: false,
                  onTap: () => context.go(AppRoutes.showcase),
                ),
                _ProfileNavItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'Ranking',
                  isSelected: false,
                  onTap: () => context.go(AppRoutes.ranking),
                ),
                _ProfileNavItem(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: false,
        actions: [
          // Botón de cerrar sesión
          TextButton(
            onPressed: () => _confirmLogout(context, ref),
            child: const Text(
              'Salir',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.error,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.sp8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.sp16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner (si existe) ─────────────────────────────────────────
            Builder(
              builder: (ctx) {
                final projectsAsync =
                    ref.watch(userProjectsProvider(user.userId));
                return projectsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (projects) {
                    final thumb = projects.isNotEmpty
                        ? projects.first.thumbnailUrl
                        : null;
                    if (thumb == null || thumb.isEmpty)
                      return const SizedBox.shrink();
                    return Container(
                      height: 140,
                      margin: const EdgeInsets.only(bottom: AppTheme.sp16),
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.bMD,
                        image: DecorationImage(
                          image: NetworkImage(thumb),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            AppTheme.black.withAlpha(89),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // ── Header de perfil ───────────────────────────────────────────
            _ProfileHeader(
              user: user,
            ),

            // ── KPIs de Docente ────────────────────────────────────
            if (user.isDocente) ...[
              const SizedBox(height: AppTheme.sp24),
              _DocenteKPIs(docenteId: user.userId),
            ],

            // ── Proyectos supervisados (solo Docente) ────────────────────────
            if (user.isDocente) ...[
              const SizedBox(height: AppTheme.sp20),
              const _SectionTitle('Proyectos supervisados'),
              const SizedBox(height: AppTheme.sp12),
              _TeacherProjectsList(docenteId: user.userId),
            ],

            const SizedBox(height: AppTheme.sp24),
            const BioDivider(),
            const SizedBox(height: AppTheme.sp16),
            const _SectionTitle('Configuración'),
            const SizedBox(height: AppTheme.sp8),
            _SettingsList(
              user: user,
              onEditProfile: () => _openEditDialog(context, ref, user),
            ),

            // ── Datos académicos ──────────────────────────────────────
            if (user.isDocente) ...[
              const _SectionTitle('Información profesional'),
              const SizedBox(height: AppTheme.sp12),

              if (user.cedula != null)
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Cédula',
                  value: user.cedula!,
                ),
              if (user.especialidadDocente != null)
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Especialidad',
                  value: user.especialidadDocente!,
                ),
              if (user.profesion != null)
                _InfoRow(
                  icon: Icons.work_outline_rounded,
                  label: 'Profesión',
                  value: user.profesion!,
                ),

              const SizedBox(height: AppTheme.sp24),

              // Grupos asignados (si los hay)
              if (user.asignaciones != null &&
                  user.asignaciones!.isNotEmpty) ...[
                _SectionTitle('Asignaciones (${user.asignaciones!.length})'),
                const SizedBox(height: AppTheme.sp12),
                ...user.asignaciones!.map(
                  (a) => _AssignmentTile(assignment: a),
                ),
              ],

              const SizedBox(height: AppTheme.sp24),
              // ── Historial de evaluaciones ──────────────────────────
              const BioDivider(),
              const SizedBox(height: AppTheme.sp24),
              const _SectionTitle('Historial de evaluaciones'),
              const SizedBox(height: AppTheme.sp12),
              _EvaluationHistory(docenteId: user.userId),
            ],

            // ── Visitante ─────────────────────────────────────────────
            if (user.isVisitante && user.organizacion != null) ...[
              const _SectionTitle('Información de visita'),
              const SizedBox(height: AppTheme.sp12),
              _InfoRow(
                icon: Icons.business_outlined,
                label: 'Organización',
                value: user.organizacion!,
              ),
            ],

            const SizedBox(height: AppTheme.sp32),

            // ── Botón de logout ───────────────────────────────────────
            BioButton(
              label: 'Cerrar sesión',
              onTap: () => _confirmLogout(context, ref),
              variant: BioButtonVariant.secondary,
              icon: Icons.logout_rounded,
            ),

            const SizedBox(height: AppTheme.sp24),

            // ── Versión de la app ─────────────────────────────────────
            const Center(
              child: Text(
                'Biofrost v1.0.0 • IntegradorHub Platform',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppTheme.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.bLG,
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'Necesitarás ingresar tus credenciales nuevamente.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditDialog(
      BuildContext context, WidgetRef ref, UserReadModel user) {
    final nameController = TextEditingController(text: user.nombre);
    final cedulaController = TextEditingController(text: user.cedula ?? '');
    final especialidadController =
        TextEditingController(text: user.especialidadDocente ?? '');
    final profesionController =
        TextEditingController(text: user.profesion ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: AppTheme.bLG,
            side: const BorderSide(color: AppTheme.border)),
        title: const Text('Editar datos personales'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
                textInputAction: TextInputAction.next,
              ),
              if (user.isDocente) ...[
                const SizedBox(height: AppTheme.sp12),
                TextField(
                  controller: cedulaController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppTheme.sp12),
                TextField(
                  controller: especialidadController,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    prefixIcon: Icon(Icons.school_outlined, size: 18),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppTheme.sp12),
                TextField(
                  controller: profesionController,
                  decoration: const InputDecoration(
                    labelText: 'Profesión',
                    prefixIcon: Icon(Icons.work_outline_rounded, size: 18),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(authProvider.notifier)
                    .updateDisplayName(newName);
                // TODO: persist cedula/especialidad/profesión via backend endpoint
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Datos actualizados'),
                      backgroundColor: AppTheme.success));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

/// Header de perfil con foto editable y badge de rol.
///
/// Equivalente del fix de foto de perfil en IntegradorHub:
/// docs/Historial_De_Avances_Completados.md § Funcionalidad de Foto de Perfil.
class _ProfileHeader extends ConsumerStatefulWidget {
  const _ProfileHeader({required this.user});
  final UserReadModel user;

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null) return;
    if (!mounted) return;

    // Recorte nativo circular 1:1
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar foto de perfil',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          cropStyle: CropStyle.circle,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Recortar foto',
          cancelButtonTitle: 'Cancelar',
          doneButtonTitle: 'Listo',
          cropStyle: CropStyle.circle,
        ),
      ],
    );
    if (croppedFile == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfilePhoto(File(croppedFile.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar con botón de cámara superpuesto
        Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              name: user.nombreCompleto,
              imageUrl: user.fotoUrl,
              size: 80,
              showBorder: true,
            ),
            if (user.isDocente || user.isAdmin)
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickAndUpload,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppTheme.borderFocus, width: 1.5),
                      boxShadow: AppTheme.shadowCard,
                    ),
                    child: _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(AppTheme.sp4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textInverse,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: AppTheme.textInverse,
                          ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.sp12),
        Text(
          user.nombreCompleto,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.sp4),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.sp8),
        _RoleBadge(user.rol),
      ],
    );
  }
}

// ── KPIs de Docente (TeacherDashboard stats) ──────────────────────────────

/// KPIs del Docente derivados de su historial de evaluaciones.
///
/// Equivalente móvil de TeacherDashboard.jsx de IntegradorHub.
/// Muestra: total evaluaciones, aprobados (≥70), con nota oficial.
class _DocenteKPIs extends ConsumerWidget {
  const _DocenteKPIs({required this.docenteId});
  final String docenteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(docenteEvaluationHistoryProvider(docenteId));

    return async.when(
      loading: () => Row(
        children: List.generate(
            3,
            (_) => Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
                    child: BioSkeleton(
                      width: double.infinity,
                      height: 72,
                      borderRadius: AppTheme.bMD,
                    ),
                  ),
                )),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (evaluations) {
        final total = evaluations.length;
        final aprobados = evaluations
            .where((e) => e.isOficial && (e.calificacion ?? 0) >= 70)
            .length;
        final conNota = evaluations.where((e) => e.hasGrade).length;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppTheme.bMD,
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.symmetric(
              vertical: AppTheme.sp14, horizontal: AppTheme.sp8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                value: '$total',
                label: 'Evaluaciones',
              ),
              _StatDivider(),
              _StatItem(
                value: '$aprobados',
                label: 'Aprobados',
                accent: AppTheme.success,
              ),
              _StatDivider(),
              _StatItem(
                value: '$conNota',
                label: 'Con nota',
                accent: AppTheme.warning,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat inline ──────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, this.accent});
  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: VerticalDivider(
        color: AppTheme.border,
        thickness: 1,
        width: AppTheme.sp24,
      ),
    );
  }
}

// ── Settings list ─────────────────────────────────────────────────────────────
class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.user, required this.onEditProfile});
  final UserReadModel user;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit_outlined, size: 20),
            title: const Text('Editar datos personales'),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: onEditProfile,
          ),
          Divider(height: 1, color: AppTheme.border),
          Consumer(builder: (ctx, r, _) {
            final mode = r.watch(themeProvider);
            final isLight = mode == AppThemeModeOption.light;
            return ListTile(
              dense: true,
              leading: Icon(
                isLight ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
              title: const Text('Tema claro'),
              trailing: Switch(
                value: isLight,
                onChanged: (v) => r.read(themeProvider.notifier).setMode(
                      v ? AppThemeModeOption.light : AppThemeModeOption.dark,
                    ),
              ),
            );
          }),
          Divider(height: 1, color: AppTheme.border),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout_rounded,
                size: 20, color: AppTheme.error),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.rol);
  final String rol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp10, vertical: AppTheme.sp4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(30),
        borderRadius: AppTheme.bFull,
        border: Border.all(color: AppTheme.borderFocus.withAlpha(80)),
      ),
      child: Text(
        rol.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textDisabled),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textDisabled,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
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

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});
  final Map<String, dynamic> assignment;

  @override
  Widget build(BuildContext context) {
    final carreraId = assignment['carreraId'] as String? ?? '—';
    final materiaId = assignment['materiaId'] as String? ?? '—';
    final grupos = assignment['gruposIds'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sp8),
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carrera: $carreraId',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            'Materia: $materiaId',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          if (grupos.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sp6),
            Wrap(
              spacing: AppTheme.sp6,
              runSpacing: AppTheme.sp4,
              children:
                  grupos.map((g) => BioChip(label: g.toString())).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Historial de evaluaciones del docente ─────────────────────────────────

class _EvaluationHistory extends ConsumerWidget {
  const _EvaluationHistory({required this.docenteId});
  final String docenteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(docenteEvaluationHistoryProvider(docenteId));

    return async.when(
      loading: () => Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp8),
            child: BioSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: AppTheme.bMD,
            ),
          ),
        ),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.sp12),
        child: Text(
          'No se pudo cargar el historial.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppTheme.textDisabled,
          ),
        ),
      ),
      data: (evaluations) {
        if (evaluations.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.sp12),
            child: Text(
              'Aún no has emitido ninguna evaluación.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textDisabled,
              ),
            ),
          );
        }
        return Column(
          children: evaluations
              .take(10)
              .map((e) => _EvalHistoryTile(evaluation: e))
              .toList(),
        );
      },
    );
  }
}

class _EvalHistoryTile extends StatelessWidget {
  const _EvalHistoryTile({required this.evaluation});
  final EvaluationReadModel evaluation;

  @override
  Widget build(BuildContext context) {
    final isOficial = evaluation.isOficial;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sp8),
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tipo + calificación + fecha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOficial ? AppTheme.badgeBlue : AppTheme.surface2,
                  borderRadius: AppTheme.bFull,
                ),
                child: Text(
                  isOficial ? 'OFICIAL' : 'SUGERENCIA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isOficial
                        ? AppTheme.badgeBlueText
                        : AppTheme.textDisabled,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (evaluation.hasGrade) ...[
                const SizedBox(width: AppTheme.sp8),
                Text(
                  '${evaluation.calificacionDisplay}/100',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                evaluation.fechaFormateada,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppTheme.textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp6),
          // Contenido truncado
          Text(
            sanitizeContent(evaluation.contenido),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lista de proyectos supervisados por el Docente ────────────────────────

/// Lista las cards de proyectos donde el Docente es titular.
/// Navega a [ProjectDetailPage] al tocar cada card.
///
/// CQRS Query: [teacherProjectsProvider] — GET /api/projects/teacher/{id}
class _TeacherProjectsList extends ConsumerWidget {
  const _TeacherProjectsList({required this.docenteId});
  final String docenteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherProjectsProvider(docenteId));

    if (state.isLoading) {
      return Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sp8),
            child: BioSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: AppTheme.bMD,
            ),
          ),
        ),
      );
    }

    if (state.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.sp8),
        child: BioErrorView(
          message: state.error?.message ?? 'Error al cargar proyectos.',
          onRetry: () => ref
              .read(teacherProjectsProvider(docenteId).notifier)
              .load(docenteId, forceRefresh: true),
        ),
      );
    }

    if (state.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.sp12),
        child: Text(
          'Aún no tienes proyectos asignados.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppTheme.textDisabled,
          ),
        ),
      );
    }

    return Column(
      children:
          state.projects.map((p) => _TeacherProjectTile(project: p)).toList(),
    );
  }
}

class _TeacherProjectTile extends StatelessWidget {
  const _TeacherProjectTile({required this.project});
  final ProjectReadModel project;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.projectDetailOf(project.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sp8),
        padding: const EdgeInsets.all(AppTheme.sp12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppTheme.bMD,
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: project.thumbnailUrl != null &&
                      project.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      project.thumbnailUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _ProjectThumbnailPlaceholder(),
                    )
                  : const _ProjectThumbnailPlaceholder(),
            ),
            const SizedBox(width: AppTheme.sp12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.materia,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (project.stackTecnologico.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sp4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: project.stackTecnologico
                          .take(3)
                          .map((s) => BioChip(label: s))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTheme.sp8),
            // Score + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if ((project.puntosTotales ?? 0) > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: AppTheme.warning),
                      const SizedBox(width: 2),
                      Text(
                        (project.puntosTotales ?? 0).toStringAsFixed(0),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppTheme.textDisabled),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectThumbnailPlaceholder extends StatelessWidget {
  const _ProjectThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.folder_copy_outlined,
        size: 20,
        color: AppTheme.textDisabled,
      ),
    );
  }
}

// ── _ProfileNavItem ────────────────────────────────────────────────────────

/// Item de navegación inferior reutilizable en la pantalla de Perfil.
class _ProfileNavItem extends StatelessWidget {
  const _ProfileNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.surface3 : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppTheme.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
