import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/project_list_item_model.dart';

/// Tarjeta compacta para lista de proyectos (group o público).
class ProjectListCard extends StatelessWidget {
  const ProjectListCard({super.key, required this.project, this.onTap});

  final ProjectListItemModel project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor(project.estado);

    return BifrostCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: título + badge de estado ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.titulo,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _EstadoBadge(estado: project.estado, color: estadoColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Materia + ciclo ───────────────────────────────────────────────
          Text(
            project.materia,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (project.ciclo != null) ...[
            const SizedBox(height: 2),
            Text(
              project.ciclo!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // ── Stack técnico ─────────────────────────────────────────────────
          if (project.stackTecnologico.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: project.stackTecnologico.take(4).map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
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
            const SizedBox(height: AppSpacing.xs),
          ],

          // ── Pie: miembros + autor ─────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.group_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                project.membersCount != null
                    ? '${project.membersCount} miembro${project.membersCount == 1 ? '' : 's'}'
                    : (project.liderNombre ?? ''),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (project.repositorioUrl != null) ...[
                const Spacer(),
                const Icon(
                  Icons.code_rounded,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 2),
                Text(
                  'Repo',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) => switch (estado.toLowerCase()) {
    'público' || 'publico' => AppColors.success,
    'borrador' => AppColors.textMuted,
    'histórico' || 'historico' => AppColors.info,
    _ => AppColors.warning,
  };
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado, required this.color});

  final String estado;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(estado, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
