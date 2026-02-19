import 'package:flutter/material.dart';

import '../../../../ui/ui_kit.dart';
import '../../data/models/evaluation_read_model.dart';

/// Tarjeta que muestra una evaluación individual.
///
/// - Tipo `oficial`: badge morado + calificación numérica
/// - Tipo `sugerencia`: badge gris + sin calificación
class EvaluationCard extends StatelessWidget {
  const EvaluationCard({super.key, required this.evaluation});

  final EvaluationReadModel evaluation;

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila superior: nombre + badge + fecha ───────────────────────
          Row(
            children: [
              // Avatar inicial
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    (evaluation.docenteNombre.isNotEmpty
                            ? evaluation.docenteNombre[0]
                            : '?')
                        .toUpperCase(),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Nombre + fecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evaluation.docenteNombre,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(evaluation.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge tipo
              _TipoBadge(tipo: evaluation.tipo),

              // Calificación
              if (evaluation.isOficial && evaluation.calificacion != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _CalificacionBadge(value: evaluation.calificacion!),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Contenido ───────────────────────────────────────────────────
          Text(
            evaluation.contenido,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

// ---------------------------------------------------------------------------
// Badge de tipo
// ---------------------------------------------------------------------------

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final String tipo;

  @override
  Widget build(BuildContext context) {
    final isOficial = tipo == 'oficial';
    final color = isOficial ? AppColors.primary : AppColors.textMuted;
    final label = isOficial ? 'Oficial' : 'Sugerencia';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge de calificación
// ---------------------------------------------------------------------------

class _CalificacionBadge extends StatelessWidget {
  const _CalificacionBadge({required this.value});

  final int value;

  Color get _color {
    if (value >= 80) return AppColors.success;
    if (value >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$value',
        style: AppTextStyles.labelLarge.copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
