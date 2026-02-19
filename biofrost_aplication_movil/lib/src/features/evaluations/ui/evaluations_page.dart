import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/evaluations_notifier.dart';
import 'widgets/evaluation_card.dart';
import 'widgets/evaluation_form.dart';

/// Página de evaluaciones para un proyecto.
///
/// [projectId] puede llegar como argumento de navegación o inyectado
/// directamente. Si está vacío se muestra un estado informativo.
class EvaluationsPage extends ConsumerStatefulWidget {
  const EvaluationsPage({super.key, required this.projectId});

  static const routeName = '/evaluations';

  final String projectId;

  @override
  ConsumerState<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends ConsumerState<EvaluationsPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    // ── Sin proyecto → estado informativo ──────────────────────────────────
    if (widget.projectId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, title: 'Evaluaciones'),
        body: const _EmptyProjectState(),
      );
    }

    final state = ref.watch(evaluationsProvider(widget.projectId));

    // ── Snackbars ──────────────────────────────────────────────────────────
    ref.listen<EvaluationsState>(evaluationsProvider(widget.projectId), (
      prev,
      next,
    ) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref
            .read(evaluationsProvider(widget.projectId).notifier)
            .clearMessages();
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref
            .read(evaluationsProvider(widget.projectId).notifier)
            .clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(
        context,
        title: 'Evaluaciones',
        isLoading: state.isLoading,
        onRefresh: () =>
            ref.read(evaluationsProvider(widget.projectId).notifier).refresh(),
      ),
      body: _buildBody(state, user),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required String title,
    bool isLoading = false,
    VoidCallback? onRefresh,
  }) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.grade_rounded,
              color: AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
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
        else if (onRefresh != null)
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: onRefresh,
            tooltip: 'Actualizar',
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.border.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildBody(EvaluationsState state, dynamic user) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError && state.evaluations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage ?? 'Error al cargar evaluaciones.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              BifrostButton(
                label: 'Reintentar',
                onPressed: () => ref
                    .read(evaluationsProvider(widget.projectId).notifier)
                    .refresh(),
                variant: BifrostButtonVariant.secondary,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Resumen calificaciones ───────────────────────────────────────
        if (state.promedioOficial != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: _PromedioCard(promedio: state.promedioOficial!),
            ),
          ),

        if (state.promedioOficial != null)
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Lista vacía ──────────────────────────────────────────────────
        if (state.evaluations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.grade_outlined,
                  color: AppColors.textMuted,
                  size: 52,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sin evaluaciones aún.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // ── Count ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Text(
                '${state.evaluations.length} evaluacion${state.evaluations.length == 1 ? '' : 'es'}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          // ── Cards ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final evaluation = state.evaluations[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: EvaluationCard(evaluation: evaluation),
                );
              }, childCount: state.evaluations.length),
            ),
          ),
        ],

        // ── Formulario (solo docente) ────────────────────────────────────
        if (user != null && user.isDocente) ...[
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Text(
                'Nueva evaluación',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            sliver: SliverToBoxAdapter(
              child: EvaluationForm(projectId: widget.projectId, user: user),
            ),
          ),
        ],

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.pagePadding + 16),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card de promedio
// ---------------------------------------------------------------------------

class _PromedioCard extends StatelessWidget {
  const _PromedioCard({required this.promedio});

  final double promedio;

  Color get _color {
    if (promedio >= 80) return AppColors.success;
    if (promedio >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return BifrostCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                promedio.toStringAsFixed(1),
                style: AppTextStyles.heading2.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calificación promedio',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Basado en evaluaciones oficiales',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
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

// ---------------------------------------------------------------------------
// Estado sin proyecto
// ---------------------------------------------------------------------------

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.grade_outlined,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sin proyecto seleccionado',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Accede a las evaluaciones desde la página detalle de un proyecto.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
