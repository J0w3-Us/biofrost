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
            _StackFilterRow(
              stacks: state.allStacks,
              selected: state.selectedStack,
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
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.warning,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Galería de Proyectos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
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
      color: AppColors.surface,
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
// Stack filter chips
// ---------------------------------------------------------------------------

class _StackFilterRow extends StatelessWidget {
  const _StackFilterRow({
    required this.stacks,
    required this.selected,
    required this.onSelected,
  });

  final List<String> stacks;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: 6,
              ),
              itemCount: stacks.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _FilterChip(
                    label: 'Todas',
                    isSelected: selected == null,
                    onTap: () => onSelected(null),
                  );
                }
                final stack = stacks[i - 1];
                return _FilterChip(
                  label: stack,
                  isSelected: selected == stack,
                  onTap: () => onSelected(selected == stack ? null : stack),
                );
              },
            ),
          ),
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      itemCount: state.filteredProjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
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
