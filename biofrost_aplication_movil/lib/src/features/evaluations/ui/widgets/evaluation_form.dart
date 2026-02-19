import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../ui/ui_kit.dart';
import '../../application/evaluations_notifier.dart';
import '../../data/models/create_evaluation_command.dart';

/// Formulario de creación de evaluación.
///
/// Solo renderiza para usuarios con rol `Docente`.
/// El [projectId] debe coincidir con el provider usado en la página padre.
class EvaluationForm extends ConsumerStatefulWidget {
  const EvaluationForm({
    super.key,
    required this.projectId,
    required this.user,
  });

  final String projectId;
  final AppUser user;

  @override
  ConsumerState<EvaluationForm> createState() => _EvaluationFormState();
}

class _EvaluationFormState extends ConsumerState<EvaluationForm> {
  final _contenidoCtrl = TextEditingController();
  String _tipo = 'sugerencia';
  double _calificacion = 70;
  bool _expanded = false;

  @override
  void dispose() {
    _contenidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cmd = CreateEvaluationCommand(
      projectId: widget.projectId,
      docenteId: widget.user.uid,
      docenteNombre: widget.user.nombreCompleto,
      tipo: _tipo,
      contenido: _contenidoCtrl.text.trim(),
      calificacion: _tipo == 'oficial' ? _calificacion.round() : null,
    );

    await ref.read(evaluationsProvider(widget.projectId).notifier).submit(cmd);

    if (mounted) {
      _contenidoCtrl.clear();
      setState(() {
        _tipo = 'sugerencia';
        _calificacion = 70;
        _expanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evaluationsProvider(widget.projectId));
    final isSubmitting = state.isSubmitting;

    return BifrostCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header colapsable ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Agregar evaluación',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Tipo ────────────────────────────────────────────────
                  Text(
                    'Tipo de evaluación',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _TipoChip(
                        label: 'Sugerencia',
                        selected: _tipo == 'sugerencia',
                        onTap: () => setState(() => _tipo = 'sugerencia'),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _TipoChip(
                        label: 'Oficial',
                        selected: _tipo == 'oficial',
                        onTap: () => setState(() => _tipo = 'oficial'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Calificación (solo oficial) ──────────────────────────
                  if (_tipo == 'oficial') ...[
                    Row(
                      children: [
                        Text(
                          'Calificación:',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${_calificacion.round()}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _scoreColor(_calificacion),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' / 100',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _scoreColor(_calificacion),
                        thumbColor: _scoreColor(_calificacion),
                        inactiveTrackColor: AppColors.border.withValues(
                          alpha: 0.4,
                        ),
                        overlayColor: _scoreColor(
                          _calificacion,
                        ).withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _calificacion,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (v) => setState(() => _calificacion = v),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // ── Contenido ────────────────────────────────────────────
                  BifrostInput(
                    label: 'Comentario',
                    controller: _contenidoCtrl,
                    hint: 'Escribe tu evaluación aquí…',
                    maxLines: 4,
                    minLines: 3,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.multiline,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Botón ────────────────────────────────────────────────
                  BifrostButton(
                    label: 'Enviar evaluación',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                    icon: Icons.send_rounded,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(double v) {
    if (v >= 80) return AppColors.success;
    if (v >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

// ---------------------------------------------------------------------------
// Chip de selección de tipo
// ---------------------------------------------------------------------------

class _TipoChip extends StatelessWidget {
  const _TipoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.border.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
