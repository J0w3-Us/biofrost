import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    // Precarga los primeros thumbnails para mejorar percepción de velocidad.
    if (!state.isLoading &&
        !state.isEmpty &&
        state.filteredProjects.isNotEmpty) {
      _precacheThumbnails(context, state.filteredProjects);
    }
    final user = ref.watch(currentUserProvider);
    final isDocente = user?.isDocente ?? false;

    return Scaffold(
      // RF-BNB: Barra de navegación inferior con 3 tabs según rol (spec §1 Barra de Navegación Inferior)
      // Visitante: Inicio / Ranking / Entrar
      // Docente  : Inicio / Ranking / Perfil
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              const Border(top: BorderSide(color: AppTheme.border, width: 1)),
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
                  icon: Icons.leaderboard_rounded,
                  label: 'Ranking',
                  isSelected: false,
                  onTap: () => context.go(AppRoutes.ranking),
                ),
                _ShowcaseNavItem(
                  icon: isDocente ? Icons.person_rounded : Icons.login_rounded,
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
          _buildAppBar(context, user?.nombre, innerBoxIsScrolled),
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

  void _precacheThumbnails(BuildContext context, List projects) {
    // Solo precachear algunas imágenes pequeñas para no bloquear la UI.
    final limit = projects.length < 4 ? projects.length : 4;
    Future.microtask(() {
      for (var i = 0; i < limit; i++) {
        final url = projects[i].thumbnailUrl;
        if (url != null && url.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  Widget _buildAppBar(
    BuildContext context,
    String? userName,
    bool scrolled,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      surfaceTintColor: Colors.transparent,
      title: Text(
        userName ?? 'Inicio',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      actions: const [],
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
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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
                        context.push(AppRoutes.projectDetailOf(project.id)),
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
  // RF-SEARCH: Debounce de 300ms para búsqueda full-text (spec §4 Dashboard)
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.ref.read(showcaseProvider.notifier);
    final state = widget.state;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: AppTheme.bFull,
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                // RF-SEARCH: 300ms debounce — spec §4 Dashboard
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 300),
                  () => notifier.applySearch(value),
                );
              },
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
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
