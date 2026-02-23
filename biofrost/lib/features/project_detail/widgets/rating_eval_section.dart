import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/services/connectivity_service.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/providers/evaluation_provider.dart';
import 'package:biofrost/features/project_detail/providers/star_rating_provider.dart';

/// Sección unificada de calificación y evaluación oficial.
///
/// Para todos los usuarios:
///   - Muestra el promedio comunitario con estrellas interactivas.
///
/// Solo Docentes (al fondo):
///   - Badge de calificación oficial vigente (si existe).
///   - Formulario para emitir o actualizar la calificación oficial (0–100).
class RatingEvalSection extends ConsumerWidget {
  const RatingEvalSection({
    super.key,
    required this.projectId,
    this.docenteTitularId,
  });

  final String projectId;
  final String? docenteTitularId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starState = ref.watch(starRatingProvider(projectId));
    final user = ref.watch(currentUserProvider);
    final isDocente = ref.watch(isDocenteProvider);

    if (starState.isLoading) return const _RatingSkeleton();
    if (starState.hasError || !starState.hasData)
      return const SizedBox.shrink();

    final rating = starState.rating!;
    final isAuthenticated = user != null;

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
          // ── Encabezado ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: AppTheme.warning),
              const SizedBox(width: AppTheme.sp6),
              const Text(
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

          // ── Promedio grande + estrellas visuales ──────────────────────
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

          // ── Estrellas interactivas ────────────────────────────────────
          _InteractiveStars(
            projectId: projectId,
            userStars: rating.userStars,
            isAuthenticated: isAuthenticated,
            isSubmitting: starState.isSubmitting,
          ),

          // ── Sección oficial (solo Docentes) ───────────────────────────
          if (isDocente && user != null) ...[
            const SizedBox(height: AppTheme.sp20),
            Divider(color: AppTheme.border.withAlpha(80), height: 1),
            const SizedBox(height: AppTheme.sp16),
            _OfficialGradePanel(
              projectId: projectId,
              docenteTitularId: docenteTitularId,
              user: user,
            ),
          ],
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

// ── Estrellas interactivas del usuario ────────────────────────────────────

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

// ── Panel de calificación oficial (solo Docentes) ─────────────────────────

class _OfficialGradePanel extends ConsumerStatefulWidget {
  const _OfficialGradePanel({
    required this.projectId,
    required this.docenteTitularId,
    required this.user,
  });

  final String projectId;
  final String? docenteTitularId;
  final dynamic user;

  @override
  ConsumerState<_OfficialGradePanel> createState() =>
      _OfficialGradePanelState();
}

class _OfficialGradePanelState extends ConsumerState<_OfficialGradePanel> {
  double _grade = 80;

  Color get _gradeColor {
    if (_grade >= 90) return AppTheme.success;
    if (_grade >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final notifier =
        ref.read(evaluationPanelProvider(widget.projectId).notifier);
    notifier.setTipo('oficial');
    notifier.setContenido('Calificación oficial');
    notifier.setCalificacion(_grade);

    final success = await notifier.submitEvaluation(
      projectId: widget.projectId,
      docenteId: widget.user.userId ?? '',
      docenteNombre: widget.user.nombreCompleto,
      docenteTitularId: widget.docenteTitularId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Calificación oficial guardada.'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final evalState = ref.watch(evaluationPanelProvider(widget.projectId));
    final canGradeOfficial =
        ref.read(evaluationRepositoryProvider).canGradeOfficially(
              userRol: widget.user.rol ?? '',
              userId: widget.user.userId,
              docenteTitularId: widget.docenteTitularId,
            );
    final isOnline = ref.watch(connectivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado oficial ────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.grade_rounded,
                size: 15, color: AppTheme.textDisabled),
            const SizedBox(width: AppTheme.sp6),
            const Text(
              'Calificación oficial',
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

        // ── Badge vigente ─────────────────────────────────────────
        if (evalState.currentGrade != null) ...[
          const SizedBox(height: AppTheme.sp12),
          _CurrentGradeBadge(evalState.currentGrade!),
        ],

        // ── Formulario (solo titular o admin) ─────────────────────
        if (canGradeOfficial) ...[
          const SizedBox(height: AppTheme.sp16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nueva calificación',
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
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _gradeColor,
                ),
                child: Text(_grade.toInt().toString()),
              ),
            ],
          ),
          Slider(
            value: _grade,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) => setState(() => _grade = v),
            activeColor: _gradeColor,
          ),
          if (!isOnline) ...[
            _OfflineBanner(),
            const SizedBox(height: AppTheme.sp8),
          ],
          BioButton(
            label: 'Guardar calificación oficial',
            onTap: (evalState.isSubmitting || !isOnline) ? null : _save,
            isLoading: evalState.isSubmitting,
            height: 44,
          ),
          if (evalState.hasSubmitError) ...[
            const SizedBox(height: AppTheme.sp8),
            Text(
              evalState.submitError?.message ?? 'Error al guardar.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.error,
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: AppTheme.sp8),
          const Text(
            'Solo el docente titular puede emitir la calificación oficial.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.textDisabled,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: _gradeColor.withAlpha(15),
        borderRadius: AppTheme.bMD,
        border: Border.all(color: _gradeColor.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(Icons.grade_rounded, color: _gradeColor, size: 18),
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

// ── Banner offline ─────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
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
              'Sin conexión — disponible al restaurarse la red.',
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

// ── Skeleton de carga ─────────────────────────────────────────────────────

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
