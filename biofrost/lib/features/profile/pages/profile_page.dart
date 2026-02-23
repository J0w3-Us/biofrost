import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:biofrost/core/models/evaluation_read_model.dart';
import 'package:biofrost/core/models/user_read_model.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';

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
      backgroundColor: AppTheme.surface0,
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go(AppRoutes.showcase),
        ),
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
            // ── Header de perfil ───────────────────────────────────────────
            _ProfileHeader(
              user: user,
            ),

            // ── KPIs de Docente ────────────────────────────────────
            if (user.isDocente) ...[  
              const SizedBox(height: AppTheme.sp24),
              _DocenteKPIs(docenteId: user.userId),
            ],

            const SizedBox(height: AppTheme.sp24),
            const BioDivider(),
            const SizedBox(height: AppTheme.sp24),

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
        backgroundColor: AppTheme.surface1,
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
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (pickedFile == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfilePhoto(File(pickedFile.path));
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
    return Row(
      children: [
        // Avatar grande con botón de cámara superpuesto
        Stack(
          children: [
            UserAvatar(
              name: user.nombreCompleto,
              imageUrl: user.fotoUrl,
              size: 72,
              showBorder: true,
            ),
            // Botón cámara circular (solo para Docentes / Admins)
            if (user.isDocente || user.isAdmin)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickAndUpload,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.black,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: AppTheme.black,
                          ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppTheme.sp16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nombreCompleto,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppTheme.sp4),
              Text(
                user.email,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.sp8),
              _RoleBadge(user.rol),
            ],
          ),
        ),
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
        children: List.generate(3, (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
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

        return Row(
          children: [
            Expanded(child: _KpiCard(
              icon: Icons.assignment_outlined,
              label: 'Evaluaciones',
              value: '$total',
            )),
            const SizedBox(width: AppTheme.sp8),
            Expanded(child: _KpiCard(
              icon: Icons.check_circle_outline_rounded,
              label: 'Aprobados',
              value: '$aprobados',
              accent: AppTheme.success,
            )),
            const SizedBox(width: AppTheme.sp8),
            Expanded(child: _KpiCard(
              icon: Icons.star_outline_rounded,
              label: 'Con nota',
              value: '$conNota',
              accent: AppTheme.warning,
            )),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppTheme.sp6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppTheme.textDisabled,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bFull,
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        rol.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
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
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDisabled,
        letterSpacing: 0.5,
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
        color: AppTheme.surface1,
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
        color: AppTheme.surface1,
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
            evaluation.contenido,
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
