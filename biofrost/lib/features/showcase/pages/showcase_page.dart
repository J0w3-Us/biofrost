import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/router/app_router.dart';
import 'package:biofrost/core/theme/app_theme.dart';
import 'package:biofrost/core/widgets/project_card.dart';
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface1,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _ShowcaseNavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  isSelected: true,
                  onTap: () {},
                ),
                _ShowcaseNavItem(
                  icon: Icons.person_rounded,
                  label: isDocente ? 'Perfil' : 'Entrar',
                  isSelected: false,
                  onTap: () => context.go(
                    isDocente ? AppRoutes.profile : AppRoutes.login,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(
              context, ref, isDocente, user?.nombre, innerBoxIsScrolled),
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
    String? userName,
    bool scrolled,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.surface0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        userName ?? 'Inicio',
        style: const TextStyle(
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
        // Login (solo visitantes)
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
      child: CustomScrollView(
        slivers: [
          // ── Badge de antigüedad del caché ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.sp16,
                AppTheme.sp8,
                AppTheme.sp16,
                AppTheme.sp4,
              ),
              child: CacheAgeBadge(savedAt: state.cachedAt),
            ),
          ),
          // ── Grid 2 columnas ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.sp16,
              AppTheme.sp4,
              AppTheme.sp16,
              AppTheme.sp40,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.sp10,
                mainAxisSpacing: AppTheme.sp10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final project = state.filteredProjects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () =>
                        context.go(AppRoutes.projectDetailOf(project.id)),
                  );
                },
                childCount: state.filteredProjects.length,
              ),
            ),
          ),
        ],
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

/// Skeleton grid mientras carga — 2 columnas.
class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.sp16,
        AppTheme.sp8,
        AppTheme.sp16,
        AppTheme.sp40,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.sp10,
        mainAxisSpacing: AppTheme.sp10,
        childAspectRatio: 0.72,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => const ProjectCardSkeleton(),
    );
  }
}

// ── _ShowcaseNavItem ──────────────────────────────────────────────────────

class _ShowcaseNavItem extends StatelessWidget {
  const _ShowcaseNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppTheme.animFast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.surface3 : Colors.transparent,
                borderRadius: AppTheme.bFull,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppTheme.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
