import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/features/evaluations/data/evaluation_repository.dart';
import 'package:biofrost/features/evaluations/domain/models/evaluation_read_model.dart';
import 'package:biofrost/features/auth/domain/models/user_read_model.dart';
import 'package:biofrost/core/services/connectivity_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/core/utils/sanitize.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';
import 'package:biofrost/features/project_detail/domain/models/star_rating_read_model.dart';
import 'package:biofrost/features/project_detail/providers/star_rating_provider.dart';
import 'package:biofrost/features/showcase/providers/projects_provider.dart';

/// Panel unificado de interacción del proyecto.
///
/// Secciones:
///   ★  Calificación comunitaria (estrellas) — visible para todos.
///   💬  Comentarios (form + historial) — requiere sesión para enviar.
///
/// CQRS:
///   Query  : [starRatingProvider], [evaluationPanelProvider].
///   Command: [StarRatingNotifier.submitRating],
///            [EvaluationPanelNotifier.submitEvaluation].
class ProjectInteractionPanel extends ConsumerStatefulWidget {
  const ProjectInteractionPanel({
    super.key,
    required this.projectId,
    this.docenteTitularId,
  });

  final String projectId;
  final String? docenteTitularId;

  @override
  ConsumerState<ProjectInteractionPanel> createState() =>
      _ProjectInteractionPanelState();
}

class _ProjectInteractionPanelState
    extends ConsumerState<ProjectInteractionPanel> {
  @override
  Widget build(BuildContext context) {
    final evalState = ref.watch(evaluationPanelProvider(widget.projectId));
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ══════════════════════════════════════════════════════════════
        // 💬  COMENTARIOS (form docente + historial)
        // ══════════════════════════════════════════════════════════════
        const BioDivider(label: 'RETROALIMENTACIÓN'),
        const SizedBox(height: AppTheme.sp16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface1,
            borderRadius: AppTheme.bLG,
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 16, color: AppTheme.textDisabled),
                    SizedBox(width: AppTheme.sp6),
                    Text(
                      'Comentarios',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDisabled,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sp14),

                // Contenido: form + historial (maneja internamente si hay user)
                if (user != null)
                  _EvalBlock(
                    projectId: widget.projectId,
                    docenteTitularId: widget.docenteTitularId,
                    evalState: evalState,
                    user: user,
                  )
                else
                  const _VisitorRatingPrompt(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ★  RATING BOTTOM BAR — fijo en la parte inferior del Scaffold
// ══════════════════════════════════════════════════════════════════════════

/// Barra de calificación comunitaria anclada al fondo de la pantalla.
class ProjectRatingBottomBar extends ConsumerWidget {
  const ProjectRatingBottomBar({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starState = ref.watch(starRatingProvider(projectId));
    final isAuthenticated = ref.watch(currentUserProvider) != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface1,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sp20,
            vertical: AppTheme.sp12,
          ),
          child: starState.isLoading
              ? const _RatingBarSkeleton()
              : (starState.hasError || !starState.hasData)
                  ? const SizedBox.shrink()
                  : _RatingBarContent(
                      projectId: projectId,
                      rating: starState.rating!,
                      isAuthenticated: isAuthenticated,
                      isSubmitting: starState.isSubmitting,
                    ),
        ),
      ),
    );
  }
}

class _RatingBarContent extends ConsumerWidget {
  const _RatingBarContent({
    required this.projectId,
    required this.rating,
    required this.isAuthenticated,
    required this.isSubmitting,
  });

  final String projectId;
  final StarRatingReadModel rating;
  final bool isAuthenticated;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(starRatingProvider(projectId), (prev, next) {
      if (next.submitError != null && prev?.submitError != next.submitError) {
        // RF-TOAST: Error de red con botón Reintentar (spec §4.4 Toast System)
        context.showError(
          'No se pudo enviar la calificación: ${next.submitError!.message}',
          onRetry: () =>
              ref.read(starRatingProvider(projectId).notifier).reload(),
        );
      }
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Score numérico
        Text(
          rating.averageDisplay,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: AppTheme.sp10),
        Container(
            width: 1,
            height: 32,
            color: AppTheme.border,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.sp10)),

        // Estrellas interactivas o de lectura según auth
        if (isAuthenticated)
          _BottomBarStars(
            projectId: projectId,
            userStars: rating.userStars,
            isSubmitting: isSubmitting,
          )
        else
          _StarBar(average: rating.average),

        const SizedBox(width: AppTheme.sp10),
        Container(
            width: 1,
            height: 32,
            color: AppTheme.border,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.sp10)),

        // Contador de votos
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${rating.totalVotes}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'votos',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppTheme.textDisabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomBarStars extends ConsumerStatefulWidget {
  const _BottomBarStars({
    required this.projectId,
    required this.userStars,
    required this.isSubmitting,
  });

  final String projectId;
  final int? userStars;
  final bool isSubmitting;

  @override
  ConsumerState<_BottomBarStars> createState() => _BottomBarStarsState();
}

class _BottomBarStarsState extends ConsumerState<_BottomBarStars> {
  int _hover = 0;

  static const double _starSize = 28.0;
  static const double _starPadH = 5.0;
  static const double _slotW = _starSize + _starPadH * 2;

  int _starFromDx(double dx) => (dx / _slotW).floor().clamp(0, 4) + 1;

  String _labelFor(int s) => switch (s) {
        5 => 'Excelente',
        4 => 'Muy bueno',
        3 => 'Bueno',
        2 => 'Regular',
        _ => 'Bajo',
      };

  Future<void> _submit(int stars) async {
    // RF-HAPTIC: feedback táctil al seleccionar estrella (spec §6 Evaluación)
    HapticFeedback.selectionClick();

    // RF-TOAST-WARN: Advertencia si ya existe evaluación previa (spec §2.1 Anti-Duplicados)
    if (widget.userStars != null && mounted) {
      context.showWarning(
        'Ya calificaste este proyecto. Tu calificación anterior será reemplazada.',
      );
    }

    // RF-MODAL: Confirmación antes de enviar (spec §6 Evaluación)
    final asyncProject = ref.read(projectDetailProvider(widget.projectId));
    final projectTitle = asyncProject.valueOrNull?.titulo ?? 'este proyecto';
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EvalConfirmDialog(
        stars: stars,
        projectTitle: projectTitle,
        isUpdate: widget.userStars != null,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _hover = 0);
    ref.read(starRatingProvider(widget.projectId).notifier).submitRating(stars);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSubmitting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warning),
      );
    }

    final active = _hover > 0 ? _hover : (widget.userStars ?? 0);
    final label = _hover > 0
        ? _labelFor(_hover)
        : (widget.userStars != null ? _labelFor(widget.userStars!) : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final local = box.globalToLocal(d.globalPosition);
            final newHover = _starFromDx(local.dx);
            if (newHover != _hover) {
              // RF-HAPTIC: click táctil al cambiar de estrella durante arrastre
              HapticFeedback.selectionClick();
            }
            setState(() => _hover = newHover);
          },
          onHorizontalDragEnd: (_) {
            if (_hover > 0) _submit(_hover);
          },
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final local = box.globalToLocal(d.globalPosition);
            _submit(_starFromDx(local.dx));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = (i + 1) <= active;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: _starPadH),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: _starSize,
                  color: AppTheme.warning,
                ),
              );
            }),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.warning,
            ),
          ),
        ],
      ],
    );
  }
}

class _RatingBarSkeleton extends StatelessWidget {
  const _RatingBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BioSkeleton(width: 40, height: 26, borderRadius: AppTheme.bSM),
        const SizedBox(width: AppTheme.sp20),
        BioSkeleton(width: 140, height: 28, borderRadius: AppTheme.bSM),
        const SizedBox(width: AppTheme.sp20),
        BioSkeleton(width: 36, height: 26, borderRadius: AppTheme.bSM),
      ],
    );
  }
}

// ── Barra estática de estrellas ───────────────────────────────────────────

class _StarBar extends StatelessWidget {
  const _StarBar({required this.average});
  final double average;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= average;
        final half = !filled && (i + 0.5) < average;
        return Padding(
          padding: const EdgeInsets.only(right: AppTheme.sp2),
          child: Icon(
            half
                ? Icons.star_half_rounded
                : filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
            size: 18,
            color: AppTheme.warning,
          ),
        );
      }),
    );
  }
}

// ── Prompt visitante ──────────────────────────────────────────────────────

class _VisitorRatingPrompt extends StatelessWidget {
  const _VisitorRatingPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16, vertical: AppTheme.sp14),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bMD,
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 16, color: AppTheme.textDisabled),
          SizedBox(width: AppTheme.sp10),
          Expanded(
            child: Text(
              'Inicia sesión para dejar comentarios y evaluaciones',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📋  EVAL BLOCK (Docentes only)
// ══════════════════════════════════════════════════════════════════════════

class _EvalBlock extends ConsumerWidget {
  const _EvalBlock({
    required this.projectId,
    required this.docenteTitularId,
    required this.evalState,
    required this.user,
  });

  final String projectId;
  final String? docenteTitularId;
  final EvaluationPanelState evalState;
  final UserReadModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Formulario de evaluación
        _EvaluationForm(
          projectId: projectId,
          docenteTitularId: docenteTitularId,
          user: user,
          state: evalState,
        ),

        const SizedBox(height: AppTheme.sp20),

        // Historial
        if (evalState.isLoading)
          const _EvalListSkeleton()
        else if (evalState.hasError)
          BioErrorView(
            message:
                evalState.error?.message ?? 'Error al cargar evaluaciones.',
            onRetry: () => ref
                .read(evaluationPanelProvider(projectId).notifier)
                .load(projectId, forceRefresh: true),
          )
        else if (evalState.evaluations.isEmpty)
          const BioEmptyView(
            message: 'Sin evaluaciones aún',
            subtitle: 'Sé el primero en evaluar este proyecto.',
            icon: Icons.rate_review_outlined,
          )
        else
          ...evalState.evaluations.map((e) => EvaluationCard(
                evaluation: e,
                projectId: projectId,
                userId: user.userId,
              )),
      ],
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
  final UserReadModel user;
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
          docenteId: widget.user.userId,
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

    final canGradeOfficial =
        ref.read(evaluationRepositoryProvider).canGradeOfficially(
              userRol: widget.user.rol,
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
              _EvalTypeToggle(
                label: 'Sugerencia',
                isSelected: state.tipo == 'sugerencia',
                onTap: () => panelNotifier.setTipo('sugerencia'),
              ),
              const SizedBox(width: AppTheme.sp8),
              if (canGradeOfficial)
                _EvalTypeToggle(
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

          // Slider calificación (solo oficial)
          if (state.tipo == 'oficial') ...[
            const SizedBox(height: AppTheme.sp12),
            _GradeSlider(
              value: state.calificacion,
              onChanged: panelNotifier.setCalificacion,
            ),
          ],

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

          if (!isOnline) ...[
            _OfflineNotice(),
            const SizedBox(height: AppTheme.sp8),
          ],

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

// ── Toggle de tipo de evaluación ──────────────────────────────────────────

class _EvalTypeToggle extends StatelessWidget {
  const _EvalTypeToggle({
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

// ── EvaluationCard (pública — usada en el historial de Docente) ───────────

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
          // Header: tipo + toggle visibilidad
          Row(
            children: [
              _EvalTypeBadge(tipo: evaluation.tipo),
              const Spacer(),
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

          // Contenido
          Text(
            sanitizeContent(evaluation.contenido),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),

          // Calificación (si aplica)
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

          // Footer: docente + fecha
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

class _EvalTypeBadge extends StatelessWidget {
  const _EvalTypeBadge({required this.tipo});
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

// ── Skeleton historial eval ───────────────────────────────────────────────

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

// ── Modal de confirmación de evaluación ──────────────────────────────────
//
// RF-MODAL: Muestra resumen (puntuación + nombre del proyecto) antes de
// enviar la calificación por estrellas (spec §6 Evaluación).

class _EvalConfirmDialog extends StatelessWidget {
  const _EvalConfirmDialog({
    required this.stars,
    required this.projectTitle,
    this.isUpdate = false,
  });

  final int stars;
  final String projectTitle;

  /// True si el usuario ya tenía un voto previo (UPSERT).
  final bool isUpdate;

  static const _labels = [
    'Bajo',
    'Regular',
    'Bueno',
    'Muy bueno',
    'Excelente',
  ];

  String get _label => stars >= 1 && stars <= 5 ? _labels[stars - 1] : '';

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ColorFilter.mode(Colors.black.withAlpha(80), BlendMode.darken),
      child: AlertDialog(
        backgroundColor: AppTheme.surface1,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.bLG),
        contentPadding: const EdgeInsets.all(AppTheme.sp24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de estrella
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 30,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(height: AppTheme.sp16),

            // Estrellas seleccionadas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Icon(
                  (i + 1) <= stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 22,
                  color: AppTheme.warning,
                );
              }),
            ),
            const SizedBox(height: AppTheme.sp4),

            // Label de la puntuación
            Text(
              _label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(height: AppTheme.sp12),

            // Título del proyecto
            Text(
              projectTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sp6),
            const Text(
              '¿Confirmas tu calificación?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            // RF-WARN: Nota de reemplazo cuando ya existe voto previo (spec §2.1)
            if (isUpdate) ...[
              const SizedBox(height: AppTheme.sp10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp12, vertical: AppTheme.sp8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(20),
                  borderRadius: AppTheme.bSM,
                  border: Border.all(color: AppTheme.warning.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppTheme.warning),
                    SizedBox(width: AppTheme.sp8),
                    Expanded(
                      child: Text(
                        'Tu calificación anterior será reemplazada.',
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
              ),
            ],
            const SizedBox(height: AppTheme.sp24),

            // Acciones
            Row(
              children: [
                // Cancelar
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppTheme.sp12),
                // Confirmar (autofocus para accesibilidad)
                Expanded(
                  child: ElevatedButton(
                    autofocus: true,
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
