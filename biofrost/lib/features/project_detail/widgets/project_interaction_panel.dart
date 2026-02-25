import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/models/comment_read_model.dart';
import 'package:biofrost/core/models/evaluation_read_model.dart';
import 'package:biofrost/core/services/connectivity_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';
import 'package:biofrost/features/project_detail/providers/comments_provider.dart';
import 'package:biofrost/features/project_detail/providers/star_rating_provider.dart';

/// Panel unificado de interacción del proyecto.
///
/// Consolida en un solo widget las 3 secciones que antes eran independientes:
///   ★  Calificación comunitaria (estrellas) — visible para todos.
///   📋  Evaluación docente (form + historial) — solo Docentes autenticados.
///   💬  Retroalimentación (comentarios + sugerencias) — todos los usuarios.
///
/// CQRS:
///   Query  : [starRatingProvider], [evaluationPanelProvider], [commentsProvider].
///   Command: [StarRatingNotifier.submitRating],
///            [EvaluationPanelNotifier.submitEvaluation],
///            [CommentsNotifier.postComment].
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

enum _PostType { comentario, sugerencia }

class _ProjectInteractionPanelState
    extends ConsumerState<ProjectInteractionPanel> {
  final _commentCtrl = TextEditingController();
  _PostType _postType = _PostType.comentario;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    if (_postType == _PostType.comentario) {
      final ok = await ref
          .read(commentsProvider(widget.projectId).notifier)
          .postComment(widget.projectId);
      if (ok && mounted) _commentCtrl.clear();
    } else {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final notifier =
          ref.read(evaluationPanelProvider(widget.projectId).notifier);
      notifier.setTipo('sugerencia');
      notifier.setContenido(_commentCtrl.text.trim());
      final success = await notifier.submitEvaluation(
        projectId: widget.projectId,
        docenteId: user.userId,
        docenteNombre: user.nombreCompleto,
        docenteTitularId: widget.docenteTitularId,
      );
      if (success && mounted) {
        _commentCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sugerencia enviada.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final starState = ref.watch(starRatingProvider(widget.projectId));
    final evalState = ref.watch(evaluationPanelProvider(widget.projectId));
    final commentsState = ref.watch(commentsProvider(widget.projectId));
    final user = ref.watch(currentUserProvider);
    final isDocente = ref.watch(isDocenteProvider);
    final isAuthenticated = user != null;
    final isOnline = ref.watch(connectivityProvider);

    final nonOfficialEvals =
        evalState.evaluations.where((e) => e.tipo != 'oficial').toList();

    final isCommentSubmitting = _postType == _PostType.comentario
        ? commentsState.isSubmitting
        : evalState.isSubmitting;
    final canPublish =
        _commentCtrl.text.isNotEmpty && !isCommentSubmitting && isOnline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ══════════════════════════════════════════════════════════════
        // ★  CALIFICACIÓN COMUNITARIA
        // ══════════════════════════════════════════════════════════════
        const BioDivider(label: 'CALIFICACIÓN'),
        const SizedBox(height: AppTheme.sp16),
        _RatingBlock(
          projectId: widget.projectId,
          starState: starState,
          isAuthenticated: isAuthenticated,
        ),

        // ══════════════════════════════════════════════════════════════
        // 📋  EVALUACIÓN (solo Docentes)
        // ══════════════════════════════════════════════════════════════
        if (isDocente && user != null) ...[
          const SizedBox(height: AppTheme.sp24),
          const BioDivider(label: 'EVALUACIÓN'),
          const SizedBox(height: AppTheme.sp16),
          _EvalBlock(
            projectId: widget.projectId,
            docenteTitularId: widget.docenteTitularId,
            evalState: evalState,
            user: user,
          ),
        ],

        // ══════════════════════════════════════════════════════════════
        // 💬  RETROALIMENTACIÓN
        // ══════════════════════════════════════════════════════════════
        const SizedBox(height: AppTheme.sp24),
        const BioDivider(label: 'RETROALIMENTACIÓN'),
        const SizedBox(height: AppTheme.sp16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con contador
            Row(
              children: [
                const Icon(Icons.forum_outlined,
                    size: 16, color: AppTheme.textDisabled),
                const SizedBox(width: AppTheme.sp6),
                const Text(
                  'Retroalimentación',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDisabled,
                    letterSpacing: 0.3,
                  ),
                ),
                if (!commentsState.isLoading &&
                    (commentsState.comments.isNotEmpty ||
                        nonOfficialEvals.isNotEmpty)) ...[
                  const SizedBox(width: AppTheme.sp8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: AppTheme.bFull,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      '${commentsState.comments.length + nonOfficialEvals.length}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.sp16),

            // Toggle Comentario / Sugerencia (solo Docentes autenticados)
            if (isDocente && isAuthenticated) ...[
              Row(
                children: [
                  _TypeChip(
                    label: 'Comentario',
                    icon: Icons.chat_bubble_outline_rounded,
                    isSelected: _postType == _PostType.comentario,
                    onTap: () =>
                        setState(() => _postType = _PostType.comentario),
                  ),
                  const SizedBox(width: AppTheme.sp8),
                  _TypeChip(
                    label: 'Sugerencia',
                    icon: Icons.lightbulb_outline_rounded,
                    isSelected: _postType == _PostType.sugerencia,
                    onTap: () =>
                        setState(() => _postType = _PostType.sugerencia),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.sp12),
            ],

            // Campo de entrada
            _InputArea(
              ctrl: _commentCtrl,
              isAuthenticated: isAuthenticated,
              isSubmitting: isCommentSubmitting,
              canPublish: canPublish,
              isOnline: isOnline,
              hintText: isAuthenticated
                  ? (_postType == _PostType.sugerencia
                      ? 'Escribe tu sugerencia para el equipo...'
                      : 'Deja un comentario sobre este proyecto...')
                  : 'Inicia sesión para comentar',
              onTextChanged: (t) {
                if (_postType == _PostType.comentario) {
                  ref
                      .read(commentsProvider(widget.projectId).notifier)
                      .setDraft(t);
                }
                setState(() {});
              },
              onPublish: _submitFeedback,
            ),

            const SizedBox(height: AppTheme.sp24),

            // Feed: comentarios + sugerencias de docentes
            if (commentsState.isLoading)
              const _CommentsSkeleton()
            else if (commentsState.hasError)
              BioErrorView(
                message: 'Error al cargar comentarios.',
                onRetry: () => ref
                    .read(commentsProvider(widget.projectId).notifier)
                    .reload(widget.projectId),
              )
            else ...[
              if (commentsState.comments.isNotEmpty)
                ...commentsState.comments
                    .map((c) => _CommentBubble(comment: c)),
              if (isDocente) ...[
                if (evalState.isLoading)
                  const _EvalFeedSkeleton()
                else if (evalState.hasError)
                  BioErrorView(
                    message: evalState.error?.message ??
                        'Error al cargar evaluaciones.',
                    onRetry: () => ref
                        .read(
                            evaluationPanelProvider(widget.projectId).notifier)
                        .load(widget.projectId, forceRefresh: true),
                  )
                else
                  ...nonOfficialEvals.map(
                    (e) => _FeedEvalCard(
                      evaluation: e,
                      projectId: widget.projectId,
                      userId: user?.userId ?? '',
                    ),
                  ),
              ],
              if (commentsState.comments.isEmpty &&
                  (!isDocente ||
                      (!evalState.isLoading &&
                          !evalState.hasError &&
                          nonOfficialEvals.isEmpty)))
                const _EmptyFeed(),
            ],
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ★  RATING BLOCK
// ══════════════════════════════════════════════════════════════════════════

class _RatingBlock extends StatelessWidget {
  const _RatingBlock({
    required this.projectId,
    required this.starState,
    required this.isAuthenticated,
  });

  final String projectId;
  final StarRatingState starState;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    if (starState.isLoading) return const _RatingSkeleton();
    if (starState.hasError || !starState.hasData)
      return const SizedBox.shrink();

    final rating = starState.rating!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bLG,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          const Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: AppTheme.warning),
              SizedBox(width: AppTheme.sp6),
              Text(
                'Calificación de la comunidad',
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
          const SizedBox(height: AppTheme.sp16),

          // Promedio + barra
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                rating.averageDisplay,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppTheme.sp16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StarBar(average: rating.average),
                    const SizedBox(height: AppTheme.sp4),
                    Text(
                      rating.averageLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sp2),
                    Text(
                      '${rating.totalVotes} calificaciones',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.sp20),
          Divider(color: AppTheme.border.withAlpha(120), height: 1),
          const SizedBox(height: AppTheme.sp16),

          // Estrellas interactivas
          _InteractiveStars(
            projectId: projectId,
            userStars: rating.userStars,
            isAuthenticated: isAuthenticated,
            isSubmitting: starState.isSubmitting,
          ),
        ],
      ),
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

// ── Estrellas interactivas ────────────────────────────────────────────────

class _InteractiveStars extends ConsumerStatefulWidget {
  const _InteractiveStars({
    required this.projectId,
    required this.userStars,
    required this.isAuthenticated,
    required this.isSubmitting,
  });

  final String projectId;
  final int? userStars;
  final bool isAuthenticated;
  final bool isSubmitting;

  @override
  ConsumerState<_InteractiveStars> createState() => _InteractiveStarsState();
}

class _InteractiveStarsState extends ConsumerState<_InteractiveStars> {
  int _hover = 0;

  static const double _starSize = 34.0;
  static const double _starPadH = 7.0;
  static const double _slotW = _starSize + _starPadH * 2;

  int _starFromDx(double dx) => (dx / _slotW).floor().clamp(0, 4) + 1;

  String _labelFor(int stars) => switch (stars) {
        5 => 'Excelente',
        4 => 'Muy bueno',
        3 => 'Bueno',
        2 => 'Regular',
        _ => 'Bajo',
      };

  void _submit(int stars) {
    setState(() => _hover = 0);
    ref.read(starRatingProvider(widget.projectId).notifier).submitRating(stars);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(starRatingProvider(widget.projectId), (prev, next) {
      if (next.submitError != null && prev?.submitError != next.submitError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'No se pudo enviar la calificación: ${next.submitError!.message}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ));
      }
    });

    if (!widget.isAuthenticated) return const _VisitorRatingPrompt();

    final active = _hover > 0 ? _hover : (widget.userStars ?? 0);
    final hasVoted = widget.userStars != null;
    final previewLabel = _hover > 0
        ? _labelFor(_hover)
        : (hasVoted ? _labelFor(widget.userStars!) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              hasVoted ? 'Tu calificación' : 'Califica este proyecto',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (previewLabel != null) ...[
              const Text(' · ', style: TextStyle(color: AppTheme.textDisabled)),
              AnimatedSwitcher(
                duration: AppTheme.animFast,
                child: Text(
                  key: ValueKey(previewLabel),
                  previewLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTheme.sp10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.isSubmitting
              ? null
              : (d) => _submit(_starFromDx(d.localPosition.dx)),
          onPanUpdate: widget.isSubmitting
              ? null
              : (d) => setState(() => _hover = _starFromDx(d.localPosition.dx)),
          onPanEnd: widget.isSubmitting
              ? null
              : (_) {
                  if (_hover > 0) _submit(_hover);
                },
          onPanCancel: () => setState(() => _hover = 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              final isActive = star <= active;
              final isPeeking = _hover > 0 && star == _hover;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: _starPadH),
                child: AnimatedScale(
                  scale: isPeeking ? 1.25 : 1.0,
                  duration: AppTheme.animFast,
                  curve: Curves.easeOut,
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: _starSize,
                    color: widget.isSubmitting
                        ? AppTheme.warning.withValues(alpha: 0.5)
                        : isActive
                            ? AppTheme.warning
                            : AppTheme.textDisabled,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppTheme.sp8),
        if (widget.isSubmitting)
          const SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.surface2,
              color: AppTheme.warning,
            ),
          )
        else
          Text(
            hasVoted
                ? 'Desliza o toca una estrella para cambiar'
                : 'Desliza o toca para calificar',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.textDisabled,
            ),
          ),
      ],
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
              'Inicia sesión como Docente para calificar este proyecto',
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

// ── Skeleton rating ───────────────────────────────────────────────────────

class _RatingSkeleton extends StatelessWidget {
  const _RatingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bLG,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BioSkeleton(width: 200, height: 14, borderRadius: AppTheme.bSM),
          const SizedBox(height: AppTheme.sp16),
          Row(
            children: [
              BioSkeleton(width: 56, height: 48, borderRadius: AppTheme.bSM),
              const SizedBox(width: AppTheme.sp16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BioSkeleton(
                      width: 100, height: 16, borderRadius: AppTheme.bSM),
                  const SizedBox(height: AppTheme.sp8),
                  BioSkeleton(
                      width: 70, height: 12, borderRadius: AppTheme.bSM),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📋  EVAL BLOCK (Docentes only)
// ══════════════════════════════════════════════════════════════════════════

class _EvalBlock extends StatelessWidget {
  const _EvalBlock({
    required this.projectId,
    required this.docenteTitularId,
    required this.evalState,
    required this.user,
  });

  final String projectId;
  final String? docenteTitularId;
  final EvaluationPanelState evalState;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge calificación vigente
        if (evalState.currentGrade != null) ...[
          _CurrentGradeBadge(evalState.currentGrade!),
          const SizedBox(height: AppTheme.sp16),
        ],

        // Formulario de evaluación
        _EvaluationForm(
          projectId: projectId,
          docenteTitularId: docenteTitularId,
          user: user,
          state: evalState,
        ),

        const SizedBox(height: AppTheme.sp20),

        // Historial
        Builder(
          builder: (context) {
            final ref = (context as Element)
                .findAncestorStateOfType<ConsumerState>()
                ?.ref;
            if (evalState.isLoading) return const _EvalListSkeleton();
            if (evalState.hasError) {
              return BioErrorView(
                message:
                    evalState.error?.message ?? 'Error al cargar evaluaciones.',
                onRetry: ref != null
                    ? () => ref
                        .read(evaluationPanelProvider(projectId).notifier)
                        .load(projectId, forceRefresh: true)
                    : null,
              );
            }
            if (evalState.evaluations.isEmpty) {
              return const BioEmptyView(
                message: 'Sin evaluaciones aún',
                subtitle: 'Sé el primero en evaluar este proyecto.',
                icon: Icons.rate_review_outlined,
              );
            }
            return Column(
              children: evalState.evaluations
                  .map((e) => EvaluationCard(
                        evaluation: e,
                        projectId: projectId,
                        userId: user.userId,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Badge calificación oficial vigente ────────────────────────────────────

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
            evaluation.contenido,
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

// ══════════════════════════════════════════════════════════════════════════
// 💬  FEEDBACK BLOCK — private helpers
// ══════════════════════════════════════════════════════════════════════════

// ── Chip de tipo de publicación ───────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.sp12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : AppTheme.surface2,
          borderRadius: AppTheme.bFull,
          border:
              Border.all(color: isSelected ? AppTheme.white : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppTheme.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.sp4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.black : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Área de entrada unificada ─────────────────────────────────────────────

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.ctrl,
    required this.isAuthenticated,
    required this.isSubmitting,
    required this.canPublish,
    required this.isOnline,
    required this.hintText,
    required this.onTextChanged,
    required this.onPublish,
  });

  final TextEditingController ctrl;
  final bool isAuthenticated;
  final bool isSubmitting;
  final bool canPublish;
  final bool isOnline;
  final String hintText;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: AppTheme.bLG,
        border: Border.all(
          color: isAuthenticated ? AppTheme.border : AppTheme.surface3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: ctrl,
            enabled: isAuthenticated,
            maxLines: 3,
            minLines: 1,
            maxLength: 500,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textDisabled,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            onChanged: onTextChanged,
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: AppTheme.sp8),
            Divider(color: AppTheme.border.withAlpha(80), height: 1),
            const SizedBox(height: AppTheme.sp8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ctrl.text.trim().length}/500',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textDisabled,
                  ),
                ),
                GestureDetector(
                  onTap: canPublish ? onPublish : null,
                  child: AnimatedOpacity(
                    opacity: canPublish ? 1.0 : 0.4,
                    duration: AppTheme.animFast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.sp16, vertical: AppTheme.sp8),
                      decoration: BoxDecoration(
                        color: canPublish ? AppTheme.white : AppTheme.surface3,
                        borderRadius: AppTheme.bFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSubmitting)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.black,
                              ),
                            )
                          else
                            const Icon(Icons.send_rounded,
                                size: 14, color: AppTheme.black),
                          const SizedBox(width: AppTheme.sp6),
                          Text(
                            isSubmitting ? 'Enviando...' : 'Publicar',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Burbuja de comentario ─────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});
  final CommentReadModel comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(comment: comment),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: comment.isOwn
                              ? AppTheme.info
                              : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.sp8),
                    Text(
                      comment.fechaDisplay,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.textDisabled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sp4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp12, vertical: AppTheme.sp10),
                  decoration: BoxDecoration(
                    color: comment.isOwn
                        ? AppTheme.info.withAlpha(20)
                        : AppTheme.surface1,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTheme.radiusMD),
                      topRight: const Radius.circular(AppTheme.radiusMD),
                      bottomLeft: Radius.circular(comment.isOwn
                          ? AppTheme.radiusMD
                          : AppTheme.radiusXS),
                      bottomRight: Radius.circular(comment.isOwn
                          ? AppTheme.radiusXS
                          : AppTheme.radiusMD),
                    ),
                    border: Border.all(
                      color: comment.isOwn
                          ? AppTheme.info.withAlpha(50)
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
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

// ── Avatar ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.comment});
  final CommentReadModel comment;

  @override
  Widget build(BuildContext context) {
    if (comment.userAvatarUrl != null) {
      return ClipOval(
        child: Image.network(
          comment.userAvatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(comment: comment),
        ),
      );
    }
    return _Initials(comment: comment);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.comment});
  final CommentReadModel comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border),
      ),
      alignment: Alignment.center,
      child: Text(
        comment.initials,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ── Feed vacío ────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.sp16),
      child: BioEmptyView(
        message: 'Sin retroalimentación aún',
        subtitle: 'Sé el primero en dejar tu opinión sobre este proyecto.',
        icon: Icons.forum_outlined,
      ),
    );
  }
}

// ── Skeleton comentarios ──────────────────────────────────────────────────

class _CommentsSkeleton extends StatelessWidget {
  const _CommentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BioSkeleton(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.circular(18)),
              const SizedBox(width: AppTheme.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BioSkeleton(
                        width: 120, height: 13, borderRadius: AppTheme.bSM),
                    const SizedBox(height: AppTheme.sp8),
                    BioSkeleton(
                        width: double.infinity,
                        height: 48,
                        borderRadius: AppTheme.bMD),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton sugerencias en feed ──────────────────────────────────────────

class _EvalFeedSkeleton extends StatelessWidget {
  const _EvalFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sp8),
          child: BioSkeleton(
            width: double.infinity,
            height: 80,
            borderRadius: AppTheme.bMD,
          ),
        ),
      ),
    );
  }
}

// ── Card de sugerencia en el feed ─────────────────────────────────────────

class _FeedEvalCard extends StatelessWidget {
  const _FeedEvalCard({
    required this.evaluation,
    required this.projectId,
    required this.userId,
  });

  final EvaluationReadModel evaluation;
  final String projectId;
  final String userId;

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: AppTheme.bFull,
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              evaluation.tipo.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDisabled,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp10),
          Text(
            evaluation.contenido,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.sp8),
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
