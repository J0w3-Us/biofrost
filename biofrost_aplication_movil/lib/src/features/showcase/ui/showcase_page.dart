import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../application/showcase_notifier.dart';
import 'project_detail_page.dart';
import 'widgets/project_showcase_card.dart';

/// Galería pública de proyectos integradores.
///
/// Muestra todos los proyectos con `es_publico = true`.
/// Permite buscar por título/materia y filtrar por tecnología.
class ShowcasePage extends ConsumerStatefulWidget {
  const ShowcasePage({super.key});

  static const routeName = '/showcase';

  @override
  ConsumerState<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends ConsumerState<ShowcasePage> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showcaseProvider);
    final notifier = ref.read(showcaseProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _ShowcaseAppBar(
        onRefresh: notifier.refresh,
        isLoading: state.isLoading,
      ),
      body: Column(
        children: [
          // ── Search + filters ─────────────────────────────────────────
          _SearchBar(
            controller: _searchCtrl,
            onChanged: notifier.search,
            enabled: !state.isLoading,
          ),

          if (state.allStacks.isNotEmpty)
            FilterChipsBar<String>(
              items: state.allStacks,
              selected: state.selectedStack,
              labelBuilder: (s) => s,
              onSelected: notifier.filterByStack,
            ),

          // ── Resultado / Conteo ───────────────────────────────────────
          if (state.status == ShowcaseStatus.success)
            _ResultCount(
              total: state.projects.length,
              filtered: state.filteredProjects.length,
              hasActiveFilter:
                  state.searchTerm.isNotEmpty || state.selectedStack != null,
              onClear: () {
                _searchCtrl.clear();
                notifier.clearFilters();
              },
            ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(child: _Body(state: state)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------

class _ShowcaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShowcaseAppBar({required this.onRefresh, required this.isLoading});

  final VoidCallback onRefresh;
  final bool isLoading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warning.withValues(alpha: 0.18),
              AppColors.surface,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: AppColors.warning.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Galería de Proyectos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: onRefresh,
                  tooltip: 'Actualizar',
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: BifrostInput(
        controller: controller,
        label: 'Buscar proyectos...',
        prefixIcon: Icons.search_rounded,
        enabled: enabled,
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result count + clear
// ---------------------------------------------------------------------------

class _ResultCount extends StatelessWidget {
  const _ResultCount({
    required this.total,
    required this.filtered,
    required this.hasActiveFilter,
    required this.onClear,
  });

  final int total;
  final int filtered;
  final bool hasActiveFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Text(
            hasActiveFilter
                ? '$filtered de $total proyecto${total != 1 ? 's' : ''}'
                : '$total proyecto${total != 1 ? 's' : ''} públicos',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          if (hasActiveFilter) ...[
            const Spacer(),
            GestureDetector(
              onTap: onClear,
              child: Text(
                'Limpiar filtros',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final ShowcaseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: ShimmerCardList(count: 6),
      );
    }

    if (state.hasError) {
      return BifrostEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Error al cargar',
        message: state.errorMessage ?? 'No se pudo conectar al servidor.',
        action: BifrostButton(
          label: 'Reintentar',
          variant: BifrostButtonVariant.primary,
          size: BifrostButtonSize.sm,
          icon: Icons.refresh_rounded,
          onPressed: () => ref.read(showcaseProvider.notifier).refresh(),
        ),
      );
    }

    if (state.isEmpty) {
      return BifrostEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        message: 'No hay proyectos que coincidan con tu búsqueda.',
        action: BifrostButton(
          label: 'Ver todos',
          variant: BifrostButtonVariant.outline,
          size: BifrostButtonSize.sm,
          icon: Icons.clear_rounded,
          onPressed: () {
            ref.read(showcaseProvider.notifier).clearFilters();
          },
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.72,
      ),
      itemCount: state.filteredProjects.length,
      itemBuilder: (context, i) {
        final project = state.filteredProjects[i];
        return ProjectShowcaseCard(
          project: project,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailPage(project: project),
              ),
            );
          },
        );
      },
    );
  }
}
