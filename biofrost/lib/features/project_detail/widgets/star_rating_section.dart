import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/project_detail/providers/star_rating_provider.dart';

/// Sección interactiva de calificación por estrellas.
///
/// - Usuarios autenticados: pueden votar/cambiar su voto.
/// - Visitantes: ven el promedio pero el tap invita a iniciar sesión.
///
/// CQRS:
/// - Query: muestra promedio + total de votos desde [starRatingProvider].
/// - Command: llama a [StarRatingNotifier.submitRating] con optimistic update.
class StarRatingSection extends ConsumerWidget {
  const StarRatingSection({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(starRatingProvider(projectId));
    final isAuthenticated = ref.watch(currentUserProvider) != null;

    if (state.isLoading) {
      return const _RatingSkeleton();
    }

    if (state.hasError || !state.hasData) {
      return const SizedBox.shrink();
    }

    final rating = state.rating!;

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
          // ── Encabezado ──────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppTheme.warning,
              ),
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

          // ── Promedio grande + estrellas ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Número grande
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

              // Columna: estrellas + etiqueta + votos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de estrellas estática (promedio visual)
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
          Divider(
            color: AppTheme.border.withAlpha(120),
            height: 1,
          ),
          const SizedBox(height: AppTheme.sp16),

          // ── Estrellas interactivas ──────────────────────────────
          _InteractiveStars(
            projectId: projectId,
            userStars: rating.userStars,
            isAuthenticated: isAuthenticated,
            isSubmitting: state.isSubmitting,
          ),
        ],
      ),
    );
  }
}

// ── Barra de estrellas estática (promedio visual) ──────────────────────────

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
  // _hover: estrella que el dedo está sobre (0 = ninguna)
  int _hover = 0;

  // Tamaño de cada "slot" táctil — debe coincidir con el Padding horizontal
  static const double _starSize = 34.0;
  static const double _starPadH = 7.0; // padding horizontal por lado
  static const double _slotW = _starSize + _starPadH * 2; // 48 px

  /// Calcula qué estrella corresponde a la coordenada x dentro del row.
  int _starFromDx(double dx) => (dx / _slotW).floor().clamp(0, 4) + 1;

  /// Etiqueta descriptiva para N estrellas.
  String _labelFor(int stars) => switch (stars) {
        5 => 'Excelente',
        4 => 'Muy bueno',
        3 => 'Bueno',
        2 => 'Regular',
        _ => 'Bajo',
      };

  void _submit(int stars) {
    setState(() => _hover = 0);
    ref
        .read(starRatingProvider(widget.projectId).notifier)
        .submitRating(stars);
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar SnackBar si falla el envío
    ref.listen(starRatingProvider(widget.projectId), (prev, next) {
      if (next.submitError != null &&
          prev?.submitError != next.submitError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'No se pudo enviar la calificación: ${next.submitError!.message}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ));
      }
    });

    // Visitante — prompt invita a iniciar sesión
    if (!widget.isAuthenticated) {
      return const _VisitorRatingPrompt();
    }

    final active = _hover > 0 ? _hover : (widget.userStars ?? 0);
    final hasVoted = widget.userStars != null;
    final previewLabel =
        _hover > 0 ? _labelFor(_hover) : (hasVoted ? _labelFor(widget.userStars!) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Instrucción + etiqueta de preview ─────────────────────────
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
              const Text(' · ',
                  style: TextStyle(color: AppTheme.textDisabled)),
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

        // ── Row de estrellas con soporte táctil + deslizable ──────────
        // Un solo GestureDetector cubre la fila completa para que
        // el dedo pueda deslizarse de estrella en estrella sin levantar.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.isSubmitting
              ? null
              : (d) => _submit(_starFromDx(d.localPosition.dx)),
          onPanUpdate: widget.isSubmitting
              ? null
              : (d) =>
                  setState(() => _hover = _starFromDx(d.localPosition.dx)),
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
                    isActive
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
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

        // ── Indicador de envío / ayuda contextual ─────────────────────
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

// ── Prompt para visitantes no autenticados ────────────────────────────────

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
          BioSkeleton(width: 180, height: 14, borderRadius: AppTheme.bSM),
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
