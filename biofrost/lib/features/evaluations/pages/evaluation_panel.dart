import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/models/evaluation_read_model.dart';
import 'package:biofrost/core/services/connectivity_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';

/// Panel de evaluaciones embebido en ProjectDetailPage.
///
/// Solo visible para Docentes autenticados.
/// CQRS: muestra historial (Query) y permite crear evaluación (Command).
class EvaluationSection extends ConsumerWidget {
  const EvaluationSection({
    super.key,
    required this.projectId,
    this.docenteTitularId,
  });

  final String projectId;
  final String? docenteTitularId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(evaluationPanelProvider(projectId));
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Calificación oficial vigente ──────────────────────────
        if (state.currentGrade != null) _CurrentGradeBadge(state.currentGrade!),

        const SizedBox(height: AppTheme.sp16),

        // ── Formulario de nueva evaluación ────────────────────────
        _EvaluationForm(
          projectId: projectId,
          docenteTitularId: docenteTitularId,
          user: user,
          state: state,
        ),

        const SizedBox(height: AppTheme.sp20),

        // ── Historial ─────────────────────────────────────────────
        if (state.isLoading)
          const _EvalListSkeleton()
        else if (state.hasError)
          BioErrorView(
            message: state.error?.message ?? 'Error al cargar evaluaciones.',
            onRetry: () => ref
                .read(evaluationPanelProvider(projectId).notifier)
                .load(projectId, forceRefresh: true),
          )
        else if (state.evaluations.isEmpty)
          const BioEmptyView(
            message: 'Sin evaluaciones aún',
            subtitle: 'Sé el primero en evaluar este proyecto.',
            icon: Icons.rate_review_outlined,
          )
        else
          ...state.evaluations.map(
            (e) => EvaluationCard(
              evaluation: e,
              projectId: projectId,
              userId: user.userId,
            ),
          ),
      ],
    );
  }
}

// ── Badge calificación oficial ─────────────────────────────────────────────

class _CurrentGradeBadge extends StatelessWidget {
  const _CurrentGradeBadge(this.grade);
  final double grade;

  Color get _gradeColor {
    if (grade >= 90) return AppTheme.success;
    if (grade >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: _gradeColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(Icons.grade_rounded, color: _gradeColor, size: 20),
          const SizedBox(width: AppTheme.sp12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calificación oficial vigente',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textDisabled,
                ),
              ),
              Text(
                grade == grade.toInt().toDouble()
                    ? grade.toInt().toString()
                    : grade.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _gradeColor,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Formulario de evaluación ──────────────────────────────────────────────

class _EvaluationForm extends ConsumerStatefulWidget {
  const _EvaluationForm({
    required this.projectId,
    required this.docenteTitularId,
    required this.user,
    required this.state,
  });

  final String projectId;
  final String? docenteTitularId;
  final dynamic user;
  final EvaluationPanelState state;

  @override
  ConsumerState<_EvaluationForm> createState() => _EvaluationFormState();
}

class _EvaluationFormState extends ConsumerState<_EvaluationForm> {
  final _contenidoCtrl = TextEditingController();

  @override
  void dispose() {
    _contenidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contenidoCtrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(evaluationPanelProvider(widget.projectId).notifier)
        .submitEvaluation(
          projectId: widget.projectId,
          docenteId: widget.user.userId ?? '',
          docenteNombre: widget.user.nombreCompleto,
          docenteTitularId: widget.docenteTitularId,
        );

    if (success && mounted) {
      _contenidoCtrl.clear();
      context.showSuccess('Evaluación enviada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelNotifier =
        ref.read(evaluationPanelProvider(widget.projectId).notifier);
    final state = widget.state;
    final isOnline = ref.watch(connectivityProvider);

    // ¿El docente puede emitir calificación oficial?
    final canGradeOfficial =
        ref.read(evaluationRepositoryProvider).canGradeOfficially(
              userRol: widget.user.rol ?? '',
              userId: widget.user.userId,
              docenteTitularId: widget.docenteTitularId,
            );

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nueva evaluación',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.sp12),

          // Toggle Tipo
          Row(
            children: [
              _TypeToggle(
                label: 'Sugerencia',
                isSelected: state.tipo == 'sugerencia',
                onTap: () => panelNotifier.setTipo('sugerencia'),
              ),
              const SizedBox(width: AppTheme.sp8),
              if (canGradeOfficial)
                _TypeToggle(
                  label: 'Oficial',
                  isSelected: state.tipo == 'oficial',
                  onTap: () => panelNotifier.setTipo('oficial'),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),

          // Contenido
          TextFormField(
            controller: _contenidoCtrl,
            onChanged: panelNotifier.setContenido,
            maxLines: 4,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Escribe tu evaluación…',
            ),
          ),

          // Slider de calificación (solo para oficial)
          if (state.tipo == 'oficial') ...[
            const SizedBox(height: AppTheme.sp12),
            _GradeSlider(
              value: state.calificacion,
              onChanged: panelNotifier.setCalificacion,
            ),
          ],

          // Error de submit
          if (state.hasSubmitError) ...[
            const SizedBox(height: AppTheme.sp8),
            Text(
              state.submitError?.message ?? 'Error al enviar.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.error,
              ),
            ),
          ],

          const SizedBox(height: AppTheme.sp12),

          // Banner offline
          if (!isOnline) _OfflineNotice(),

          if (!isOnline) const SizedBox(height: AppTheme.sp8),

          // Botón enviar
          BioButton(
            label: 'Enviar evaluación',
            onTap: (state.isSubmitting || !isOnline) ? null : _submit,
            isLoading: state.isSubmitting,
            height: 44,
          ),
        ],
      ),
    );
  }
}

// ── Slider de calificación ────────────────────────────────────────────────

class _GradeSlider extends StatelessWidget {
  const _GradeSlider({required this.value, required this.onChanged});
  final double value;
  final void Function(double) onChanged;

  Color get _color {
    if (value >= 90) return AppTheme.success;
    if (value >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Calificación',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textDisabled,
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: AppTheme.animFast,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
              child: Text(value.toInt().toString()),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: onChanged,
          activeColor: _color,
        ),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : AppTheme.surface2,
          borderRadius: AppTheme.bFull,
          border: Border.all(
            color: isSelected ? AppTheme.white : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── EvaluationCard ────────────────────────────────────────────────────────

class EvaluationCard extends ConsumerWidget {
  const EvaluationCard({
    super.key,
    required this.evaluation,
    required this.projectId,
    required this.userId,
  });

  final EvaluationReadModel evaluation;
  final String projectId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sp8),
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: tipo + visibilidad ────────────────────────────
          Row(
            children: [
              _TypeBadge(tipo: evaluation.tipo),
              const Spacer(),
              // Toggle visibilidad (Optimistic Update)
              GestureDetector(
                onTap: () => ref
                    .read(evaluationPanelProvider(projectId).notifier)
                    .toggleVisibility(evaluation, userId, projectId),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: evaluation.esPublico
                        ? AppTheme.badgeGreen
                        : AppTheme.surface2,
                    borderRadius: AppTheme.bFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        evaluation.esPublico
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 11,
                        color: evaluation.esPublico
                            ? AppTheme.badgeGreenText
                            : AppTheme.textDisabled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        evaluation.esPublico ? 'Público' : 'Privado',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: evaluation.esPublico
                              ? AppTheme.badgeGreenText
                              : AppTheme.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.sp10),

          // ── Contenido ─────────────────────────────────────────────
          Text(
            evaluation.contenido,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),

          // ── Calificación (si aplica) ──────────────────────────────
          if (evaluation.hasGrade) ...[
            const SizedBox(height: AppTheme.sp12),
            Row(
              children: [
                const Icon(Icons.grade_rounded,
                    color: AppTheme.warning, size: 14),
                const SizedBox(width: AppTheme.sp4),
                Text(
                  evaluation.calificacionDisplay ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
                const Text(
                  ' / 100',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textDisabled,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppTheme.sp8),

          // ── Footer: docente + fecha ───────────────────────────────
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 11, color: AppTheme.textDisabled),
              const SizedBox(width: 4),
              Text(
                evaluation.docenteNombre,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textDisabled,
                ),
              ),
              const Spacer(),
              Text(
                evaluation.fechaFormateada,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.tipo});
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final isOficial = tipo == 'oficial';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOficial ? AppTheme.badgeBlue : AppTheme.surface2,
        borderRadius: AppTheme.bFull,
        border: Border.all(
          color: isOficial
              ? AppTheme.badgeBlueText.withAlpha(77)
              : AppTheme.border,
        ),
      ),
      child: Text(
        isOficial ? 'OFICIAL' : 'SUGERENCIA',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isOficial ? AppTheme.badgeBlueText : AppTheme.textDisabled,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Aviso offline ─────────────────────────────────────────────────────────

class _OfflineNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp12, vertical: AppTheme.sp8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha(20),
        borderRadius: AppTheme.bSM,
        border: Border.all(color: AppTheme.warning.withAlpha(80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: AppTheme.warning),
          SizedBox(width: AppTheme.sp8),
          Expanded(
            child: Text(
              'Sin conexión — el envío estará disponible cuando se restaure la red.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppTheme.warning,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton historial ────────────────────────────────────────────────────

class _EvalListSkeleton extends StatelessWidget {
  const _EvalListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp8),
          child: BioSkeleton(
            width: double.infinity,
            height: 88,
            borderRadius: AppTheme.bMD,
          ),
        ),
      ),
    );
  }
}
