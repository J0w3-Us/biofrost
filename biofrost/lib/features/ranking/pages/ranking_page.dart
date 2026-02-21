import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/showcase/providers/projects_provider.dart';

/// Pantalla de Ranking — clasificación de proyectos por puntuación.
///
/// Divide la lista en:
/// - [_Podium]  → Top 3 con medallas visuales
/// - [_Table]   → Posiciones 4–20 en lista
class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rankingProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface0,
      appBar: AppBar(
        title: const Text('Ranking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go(AppRoutes.showcase),
        ),
      ),
      body: _buildBody(context, state, ref),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RankingState state,
    WidgetRef ref,
  ) {
    if (state.isLoading) return const _RankingSkeleton();

    if (state.hasError) {
      return BioErrorView(
        message: state.error?.message ?? 'Error al cargar el ranking.',
        isOffline: state.error is NetworkException,
        onRetry: () =>
            ref.read(rankingProvider.notifier).load(forceRefresh: true),
      );
    }

    if (state.projects.isEmpty) {
      return const BioEmptyView(
        message: 'Ranking vacío',
        subtitle: 'Aún no hay proyectos calificados.',
        icon: Icons.emoji_events_outlined,
      );
    }

    return RefreshIndicator(
      color: AppTheme.white,
      backgroundColor: AppTheme.surface2,
      onRefresh: () =>
          ref.read(rankingProvider.notifier).load(forceRefresh: true),
      child: CustomScrollView(
        slivers: [
          // Distintivo de antigüedad del caché
          SliverToBoxAdapter(
            child: CacheAgeBadge(savedAt: state.cachedAt),
          ),
          // Podio top 3
          SliverToBoxAdapter(
            child: _Podium(projects: state.podium),
          ),
          // Separador
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.sp16,
                vertical: AppTheme.sp8,
              ),
              child: BioDivider(label: 'CLASIFICACIÓN'),
            ),
          ),
          // Tabla 4+
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final project = state.table[index];
                final position = index + 4;
                return _RankingRow(
                  project: project,
                  position: position,
                  onTap: () => context.go(
                    AppRoutes.projectDetailOf(project.id),
                  ),
                );
              },
              childCount: state.table.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.sp40)),
        ],
      ),
    );
  }
}

// ── Podio visual ─────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.projects});
  final List<ProjectReadModel> projects;

  @override
  Widget build(BuildContext context) {
    // Reordenar: 2°, 1°, 3°
    final ordered = [
      if (projects.length > 1) projects[1],
      if (projects.isNotEmpty) projects[0],
      if (projects.length > 2) projects[2],
    ];

    // Alturas relativas del podio
    final heights = [
      if (projects.length > 1) 90.0,
      if (projects.isNotEmpty) 110.0,
      if (projects.length > 2) 75.0,
    ];

    final positions = [
      if (projects.length > 1) 2,
      if (projects.isNotEmpty) 1,
      if (projects.length > 2) 3,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.sp16,
        AppTheme.sp24,
        AppTheme.sp16,
        AppTheme.sp16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(ordered.length, (i) {
          return Expanded(
            child: _PodiumColumn(
              project: ordered[i],
              position: positions[i],
              height: heights[i],
            ),
          );
        }),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.project,
    required this.position,
    required this.height,
  });

  final ProjectReadModel project;
  final int position;
  final double height;

  static const _medals = ['🥇', '🥈', '🥉'];
  static final _colors = [
    AppTheme.podiumGold,
    AppTheme.podiumSilver,
    AppTheme.podiumBronze,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[position - 1];
    final medal = _medals[position - 1];
    final isFirst = position == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medalla
          Text(medal, style: TextStyle(fontSize: isFirst ? 28 : 22)),
          const SizedBox(height: AppTheme.sp6),

          // Título del proyecto (abreviado)
          Text(
            project.titulo,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isFirst ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Puntos
          if (project.puntosTotales != null) ...[
            const SizedBox(height: AppTheme.sp4),
            Text(
              '${project.puntosTotales} pts',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.sp8),

          // Columna del podio
          Container(
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.surface1,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusSM),
              ),
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Center(
              child: Text(
                '#$position',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color.withAlpha(200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de la tabla de ranking ───────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.project,
    required this.position,
    required this.onTap,
  });

  final ProjectReadModel project;
  final int position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16,
          vertical: AppTheme.sp14,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            // Posición
            SizedBox(
              width: 32,
              child: Text(
                '#$position',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.sp12),

            // Info del proyecto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.titulo,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.sp2),
                  Text(
                    project.liderNombre ?? project.materia,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textDisabled,
                    ),
                  ),
                ],
              ),
            ),

            // Puntos
            if (project.puntosTotales != null)
              Text(
                '${project.puntosTotales}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),

            const SizedBox(width: AppTheme.sp8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textDisabled, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ────────────────────────────────────────────────────────

class _RankingSkeleton extends StatelessWidget {
  const _RankingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Podio skeleton
        Container(
          height: 200,
          margin: const EdgeInsets.all(AppTheme.sp16),
          decoration: BoxDecoration(
            color: AppTheme.surface1,
            borderRadius: AppTheme.bMD,
          ),
        ),
        ...List.generate(
          6,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.sp16,
              vertical: AppTheme.sp8,
            ),
            child: BioSkeleton(
              width: double.infinity,
              height: 52,
              borderRadius: AppTheme.bMD,
            ),
          ),
        ),
      ],
    );
  }
}
