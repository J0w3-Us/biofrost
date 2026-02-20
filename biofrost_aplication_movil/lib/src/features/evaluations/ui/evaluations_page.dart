import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/evaluations_notifier.dart';
import '../data/models/evaluation_read_model.dart';
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
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.22),
              AppColors.surface,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryVariant],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.grade_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
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
          ),
        ),
      ),
    );
  }

  Widget _buildBody(EvaluationsState state, dynamic user) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: ShimmerCardList(count: 5),
      );
    }

    if (state.hasError && state.evaluations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: GlassCard(
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
                GradientButton(
                  label: 'Reintentar',
                  onPressed: () => ref
                      .read(evaluationsProvider(widget.projectId).notifier)
                      .refresh(),
                ),
              ],
            ),
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
              child: _ScoreHeaderCard(promedio: state.promedioOficial!),
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
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _TimelineItem(
                  evaluation: state.evaluations[i],
                  isLast: i == state.evaluations.length - 1,
                ),
                childCount: state.evaluations.length,
              ),
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
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryVariant],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nueva evaluación',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
// Score header card (GlassCard + ScoreRing)
// ---------------------------------------------------------------------------

class _ScoreHeaderCard extends StatelessWidget {
  const _ScoreHeaderCard({required this.promedio});

  final double promedio;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      glowColor: AppColors.primary,
      child: Row(
        children: [
          ScoreRing(score: promedio, size: 72),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calificación promedio',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Evaluaciones oficiales de docentes',
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
// Timeline item
// ---------------------------------------------------------------------------

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.evaluation, required this.isLast});

  final EvaluationReadModel evaluation;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: dot + connector line
        SizedBox(
          width: 28,
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: evaluation.isOficial
                      ? AppColors.primary
                      : AppColors.textMuted,
                  shape: BoxShape.circle,
                  boxShadow: evaluation.isOficial
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 56,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.border.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        // Right: card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: EvaluationCard(evaluation: evaluation),
          ),
        ),
      ],
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
        child: GlassCard(
          glowColor: AppColors.primary,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primaryVariant.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grade_outlined,
                  color: AppColors.primary,
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
      ),
    );
  }
}
