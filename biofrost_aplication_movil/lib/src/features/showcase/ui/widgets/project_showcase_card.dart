import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/public_project_read_model.dart';

/// Tarjeta compacta de un proyecto público para el grid de la galería.
class ProjectShowcaseCard extends StatelessWidget {
  const ProjectShowcaseCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final PublicProjectReadModel project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BifrostCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: imagen o gradiente ────────────────────────────────
            _CardHeader(project: project),

            // ── Contenido ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    project.titulo,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Materia + Ciclo
                  Row(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${project.materia} · ${project.ciclo}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Descripción breve
                  if (project.displayDescription.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      project.displayDescription,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),

                  // Stack chips (máx 3)
                  _StackChips(stacks: project.stackTecnologico),

                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.sm),

                  // Footer: integrantes + líder
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.miembrosCount} integrante${project.miembrosCount != 1 ? 's' : ''}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (project.hasRepo)
                        const Icon(
                          Icons.code_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                      if (project.hasDemo) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: AppColors.info,
                        ),
                      ],
                      if (project.hasVideo) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Header: thumbnail si existe, si no — gradiente generativo por stack.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.project});

  final PublicProjectReadModel project;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.md),
        topRight: Radius.circular(AppRadius.md),
      ),
      child: SizedBox(
        height: 110,
        width: double.infinity,
        child: project.hasThumbnail
            ? Image.network(
                project.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _GradientHeader(project: project),
              )
            : _GradientHeader(project: project),
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.project});

  final PublicProjectReadModel project;

  static Color _colorForStack(List<String> stack) {
    if (stack.isEmpty) return AppColors.primary;
    final s = stack.first.toLowerCase();
    if (s.contains('flutter') || s.contains('dart')) {
      return const Color(0xFF54C5F8);
    }
    if (s.contains('react') || s.contains('next')) {
      return const Color(0xFF61DAFB);
    }
    if (s.contains('.net') || s.contains('c#') || s.contains('csharp')) {
      return const Color(0xFF512BD4);
    }
    if (s.contains('python') || s.contains('django') || s.contains('flask')) {
      return const Color(0xFF3776AB);
    }
    if (s.contains('node') || s.contains('express') || s.contains('js')) {
      return const Color(0xFF68A063);
    }
    if (s.contains('firebase') || s.contains('google')) {
      return const Color(0xFFFFA000);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStack(project.stackTecnologico);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.85), AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.rocket_launch_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 40,
        ),
      ),
    );
  }
}

/// Chips del stack tecnológico (máx 3 + overflow).
class _StackChips extends StatelessWidget {
  const _StackChips({required this.stacks});

  final List<String> stacks;

  @override
  Widget build(BuildContext context) {
    if (stacks.isEmpty) return const SizedBox.shrink();

    final visible = stacks.take(3).toList();
    final overflow = stacks.length - visible.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ...visible.map((s) => _TechChip(label: s)),
        if (overflow > 0) _TechChip(label: '+$overflow', muted: true),
      ],
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.surfaceVariant
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: muted
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: muted ? AppColors.textMuted : AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
