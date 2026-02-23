import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/ui_kit.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/showcase/providers/projects_provider.dart';

/// Galería pública de proyectos.
///
/// Accesible para Visitantes y Docentes.
/// Conecta con:
/// - [showcaseProvider] → obtiene proyectos, maneja filtros
/// - [currentUserProvider] → muestra/oculta botón de login
class ShowcasePage extends ConsumerWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(showcaseProvider);
    final user = ref.watch(currentUserProvider);
    final isDocente = user?.isDocente ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surface0,
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.testLogin),
              label: const Text('Test Login'),
              icon: const Icon(Icons.login_rounded),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context, ref, isDocente, innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _SearchAndFilters(state: state, ref: ref),

            // ── Contenido ────────────────────────────────────────────
            Expanded(
              child: _buildBody(context, state, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    bool isDocente,
    bool scrolled,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.surface0,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Showcase',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        // Botón Ranking
        IconButton(
          icon: const Icon(Icons.leaderboard_rounded,
              color: AppTheme.textSecondary),
          tooltip: 'Ranking',
          onPressed: () => context.go(AppRoutes.ranking),
        ),
        // Login / Perfil
        if (!isDocente)
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text(
              'Docente',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.person_rounded, color: AppTheme.textPrimary),
            tooltip: 'Perfil',
            onPressed: () => context.go(AppRoutes.profile),
          ),
        const SizedBox(width: AppTheme.sp8),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ShowcaseState state,
    WidgetRef ref,
  ) {
    // Estado de carga
    if (state.isLoading) {
      return _SkeletonGrid();
    }

    // Error
    if (state.hasError) {
      return BioErrorView(
        message: state.error?.message ?? 'Error al cargar proyectos.',
        isOffline: state.error is NetworkException,
        onRetry: () =>
            ref.read(showcaseProvider.notifier).load(forceRefresh: true),
      );
    }

    // Lista vacía (por filtro)
    if (state.isEmpty) {
      return const BioEmptyView(
        message: 'Sin resultados',
        subtitle: 'Intenta con otro término o tecnología.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.white,
      backgroundColor: AppTheme.surface2,
      onRefresh: () =>
          ref.read(showcaseProvider.notifier).load(forceRefresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.sp16,
          AppTheme.sp8,
          AppTheme.sp16,
          AppTheme.sp40,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: AppTheme.sp12,
          childAspectRatio: 2.3,
        ),
        itemCount: state.filteredProjects.length + 1,
        itemBuilder: (context, index) {
          // ── Badge de antigüedad del caché (primer slot) ──────────
          if (index == 0) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.sp4),
                child: CacheAgeBadge(savedAt: state.cachedAt),
              ),
            );
          }
          final project = state.filteredProjects[index - 1];
          return ProjectCard(
            project: project,
            onTap: () => context.go(AppRoutes.projectDetailOf(project.id)),
          );
        },
      ),
    );
  }
}

// ── SearchBar + chips de filtro ───────────────────────────────────────────

class _SearchAndFilters extends StatefulWidget {
  const _SearchAndFilters({required this.state, required this.ref});
  final ShowcaseState state;
  final WidgetRef ref;

  @override
  State<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<_SearchAndFilters> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.ref.read(showcaseProvider.notifier);
    final state = widget.state;

    return Container(
      color: AppTheme.surface0,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.sp16,
        AppTheme.sp8,
        AppTheme.sp16,
        AppTheme.sp4,
      ),
      child: Column(
        children: [
          // SearchBar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: AppTheme.bFull,
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: notifier.applySearch,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar proyectos…',
                hintStyle: const TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textDisabled,
                  size: 18,
                ),
                suffixIcon: state.searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppTheme.textDisabled),
                        onPressed: () {
                          _searchCtrl.clear();
                          notifier.applySearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: AppTheme.sp16,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.sp8),

          // Filter chips de stack
          if (state.allStacks.isNotEmpty)
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.allStacks.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.sp6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return BioChip(
                      label: 'Todos',
                      isSelected: state.selectedStack == null,
                      onTap: () => notifier.applyStackFilter(null),
                    );
                  }
                  final stack = state.allStacks[index - 1];
                  return BioChip(
                    label: stack,
                    isSelected: state.selectedStack == stack,
                    onTap: () => notifier.applyStackFilter(stack),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── ProjectCard ───────────────────────────────────────────────────────────

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final ProjectReadModel project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila: estado + materia ──────────────────────────────
          Row(
            children: [
              StatusBadge(estado: project.estado),
              const Spacer(),
              Text(
                project.materia,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textDisabled,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.sp10),

          // ── Título ────────────────────────────────────────────────
          Text(
            project.titulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.sp6),

          // ── Líder ─────────────────────────────────────────────────
          if (project.liderNombre != null)
            Row(
              children: [
                UserAvatar(
                  name: project.liderNombre!,
                  imageUrl: project.liderFotoUrl,
                  size: 20,
                  showBorder: true,
                ),
                const SizedBox(width: AppTheme.sp6),
                Expanded(
                  child: Text(
                    project.liderNombre!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const Spacer(),

          // ── Stack chips ───────────────────────────────────────────
          Row(
            children: [
              ...project.stackPreview.map(
                (tech) => Padding(
                  padding: const EdgeInsets.only(right: AppTheme.sp6),
                  child: _StackMini(tech),
                ),
              ),
              if (project.stackOverflow > 0)
                _StackMini('+${project.stackOverflow}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StackMini extends StatelessWidget {
  const _StackMini(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: AppTheme.bFull,
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Skeleton grid mientras carga.
class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.sp16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sp12),
      itemBuilder: (_, __) => const ProjectCardSkeleton(),
    );
  }
}
