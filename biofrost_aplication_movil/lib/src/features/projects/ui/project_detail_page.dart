import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/project_detail_notifier.dart';
import '../data/models/add_member_command.dart';
import '../data/models/project_detail_model.dart';
import '../data/models/update_project_command.dart';
import 'widgets/canvas_viewer.dart';
import 'widgets/project_member_chip.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  static const routeName = '/projects/detail';

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(projectDetailProvider(projectId));

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.hasError || !state.hasProject) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: const Text(
            'Detalle',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage ?? 'Proyecto no encontrado',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              BifrostButton(
                label: 'Reintentar',
                variant: BifrostButtonVariant.secondary,
                onPressed: () =>
                    ref.read(projectDetailProvider(projectId).notifier).load(),
              ),
            ],
          ),
        ),
      );
    }

    final project = state.project!;
    final isLeader = user?.uid == project.liderId;
    final isAlumno = user?.isAlumno ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          project.titulo,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          if (isLeader && isAlumno)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
              ),
              color: AppColors.surface,
              onSelected: (value) => _handleMenu(
                context,
                ref,
                value,
                project.liderId,
                user?.uid ?? '',
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Editar proyecto',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const PopupMenuItem(
                  value: 'visibility',
                  child: Text(
                    'Cambiar visibilidad',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Eliminar proyecto',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(projectDetailProvider(projectId).notifier).load(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info básica ─────────────────────────────────────────────
              _InfoSection(project: project),
              const SizedBox(height: AppSpacing.lg),

              // ── Miembros ─────────────────────────────────────────────────
              _MembersSection(
                project: project,
                isLeader: isLeader,
                currentUserId: user?.uid ?? '',
                onAddMember: isLeader
                    ? () => _showAddMemberDialog(context, ref, user?.uid ?? '')
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Stack técnico ────────────────────────────────────────────
              if (project.stackTecnologico.isNotEmpty) ...[
                _SectionTitle(title: 'Stack Tecnológico'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: project.stackTecnologico.map((tech) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tech,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Canvas ────────────────────────────────────────────────────
              if (project.canvas.isNotEmpty) ...[
                _SectionTitle(title: 'Descripción del Proyecto'),
                const SizedBox(height: AppSpacing.sm),
                BifrostCard(child: CanvasViewer(blocks: project.canvas)),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Enlaces ───────────────────────────────────────────────────
              if (project.repositorioUrl != null ||
                  project.videoUrl != null) ...[
                _SectionTitle(title: 'Recursos'),
                const SizedBox(height: AppSpacing.sm),
                if (project.repositorioUrl != null)
                  _ResourceTile(
                    icon: Icons.code_rounded,
                    label: 'Repositorio',
                    url: project.repositorioUrl!,
                  ),
                if (project.videoUrl != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ResourceTile(
                    icon: Icons.play_circle_rounded,
                    label: 'Demo / Video',
                    url: project.videoUrl!,
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
    String leaderId,
    String currentUserId,
  ) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, ref);
        break;
      case 'visibility':
        _toggleVisibility(context, ref);
        break;
      case 'delete':
        _confirmDelete(context, ref, currentUserId);
        break;
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final project = ref.read(projectDetailProvider(projectId)).project;
    if (project == null) return;

    final tituloCtrl = TextEditingController(text: project.titulo);
    final videoCtrl = TextEditingController(text: project.videoUrl ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Proyecto',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: videoCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Video URL (opcional)',
                labelStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(projectDetailProvider(projectId).notifier)
                  .update(
                    UpdateProjectCommand(
                      titulo: tituloCtrl.text,
                      videoUrl: videoCtrl.text.isEmpty ? null : videoCtrl.text,
                    ),
                  );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(BuildContext context, WidgetRef ref) {
    final project = ref.read(projectDetailProvider(projectId)).project;
    if (project == null) return;

    ref
        .read(projectDetailProvider(projectId).notifier)
        .update(
          UpdateProjectCommand(
            titulo: project.titulo,
            esPublico: !project.esPublico,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          project.esPublico
              ? 'Proyecto ahora es privado'
              : 'Proyecto ahora es público',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar Proyecto',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          '¿Confirmas eliminar este proyecto? Se liberarán todos los miembros.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(projectDetailProvider(projectId).notifier)
                  .deleteProject(currentUserId);
              if (ok && context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
    String leaderId,
  ) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Agregar Miembro',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: emailCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Email o Matrícula',
            labelStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final input = emailCtrl.text.trim();
              if (input.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(projectDetailProvider(projectId).notifier)
                  .addMember(
                    AddMemberCommand(
                      leaderId: leaderId,
                      emailOrMatricula: input,
                    ),
                  );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Secciones
// ---------------------------------------------------------------------------

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.project});

  final ProjectDetailModel project;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.materia,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _EstadoBadge(estado: project.estado),
            ],
          ),
          if (project.ciclo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              project.ciclo,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                project.esPublico ? 'Público' : 'Privado',
                style: AppTextStyles.caption.copyWith(
                  color: project.esPublico
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.project,
    required this.isLeader,
    required this.currentUserId,
    this.onAddMember,
  });

  final ProjectDetailModel project;
  final bool isLeader;
  final String currentUserId;
  final VoidCallback? onAddMember;

  @override
  Widget build(BuildContext context) {
    final members = project.members;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(title: 'Equipo (${members.length}/5)'),
            if (isLeader && members.length < 5)
              GestureDetector(
                onTap: onAddMember,
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: members.map<Widget>((m) {
            final isLeaderMember = m.id == project.liderId;
            return ProjectMemberChip(member: m, isLeader: isLeaderMember);
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado.toLowerCase()) {
      'público' || 'publico' => AppColors.success,
      'borrador' => AppColors.textMuted,
      'histórico' || 'historico' => AppColors.info,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(estado, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      onTap: null, // URL launcher can be added later
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  url,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
