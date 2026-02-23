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
  int _hover = 0;

  @override
  Widget build(BuildContext context) {
    final activeStars = _hover > 0 ? _hover : (widget.userStars ?? 0);
    final hasVoted = widget.userStars != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasVoted
              ? 'Tu calificación — toca para cambiarla'
              : widget.isAuthenticated
                  ? 'Califica este proyecto'
                  : 'Inicia sesión para calificar',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.sp10),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            final isActive = star <= activeStars;

            return GestureDetector(
              onTap: widget.isAuthenticated && !widget.isSubmitting
                  ? () {
                      ref
                          .read(starRatingProvider(widget.projectId).notifier)
                          .submitRating(star);
                    }
                  : null,
              onPanUpdate:
                  widget.isAuthenticated ? (_) {} : null, // evita interferencia
              child: MouseRegion(
                onEnter: (_) => setState(() => _hover = star),
                onExit: (_) => setState(() => _hover = 0),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  padding: const EdgeInsets.all(AppTheme.sp4),
                  child: widget.isSubmitting
                      ? Icon(
                          Icons.star_rounded,
                          size: 32,
                          color: isActive
                              ? AppTheme.warning.withAlpha(120)
                              : AppTheme.surface3,
                        )
                      : Icon(
                          isActive
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 32,
                          color: isActive
                              ? AppTheme.warning
                              : widget.isAuthenticated
                                  ? AppTheme.textDisabled
                                  : AppTheme.surface3,
                        ),
                ),
              ),
            );
          }),
        ),
        if (widget.isSubmitting) ...[
          const SizedBox(height: AppTheme.sp8),
          const SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.surface2,
              color: AppTheme.warning,
            ),
          ),
        ],
      ],
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
