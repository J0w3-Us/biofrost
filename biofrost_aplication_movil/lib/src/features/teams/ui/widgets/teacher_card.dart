import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/teacher_read_model.dart';

/// Tarjeta que muestra un docente disponible para el grupo.
///
/// Los docentes con materia de alta prioridad muestran un badge especial.
class TeacherCard extends StatelessWidget {
  const TeacherCard({super.key, required this.teacher});

  final TeacherReadModel teacher;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          // ── Avatar ─────────────────────────────────────────────────────
          _TeacherAvatar(
            initials: teacher.initials,
            isAltaPrioridad: teacher.esAltaPrioridad,
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Info ───────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.nombreCompleto,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  teacher.asignatura.isNotEmpty
                      ? teacher.asignatura
                      : teacher.profesion,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (teacher.profesion.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    teacher.profesion,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // ── Badge ──────────────────────────────────────────────────────
          if (teacher.esAltaPrioridad)
            _AltaPrioridadBadge()
          else
            _DocenteBadge(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar con anillo de alta prioridad
// ---------------------------------------------------------------------------

class _TeacherAvatar extends StatelessWidget {
  const _TeacherAvatar({required this.initials, required this.isAltaPrioridad});

  final String initials;
  final bool isAltaPrioridad;

  @override
  Widget build(BuildContext context) {
    final color = isAltaPrioridad ? AppColors.warning : AppColors.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: isAltaPrioridad
            ? Border.all(
                color: AppColors.warning.withValues(alpha: 0.6),
                width: 1.5,
              )
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class _AltaPrioridadBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            'Integradora',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocenteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Docente',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
