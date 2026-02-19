import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/teams_notifier.dart';
import 'widgets/student_card.dart';
import 'widgets/teacher_card.dart';

/// Página de equipos — muestra alumnos disponibles y docentes del grupo.
///
/// Usa el [groupId] del usuario autenticado para filtrar los datos.
/// Si el usuario no tiene grupo asignado, muestra un estado informativo.
class TeamsPage extends ConsumerStatefulWidget {
  const TeamsPage({super.key});

  static const routeName = '/teams';

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final groupId = user?.grupoId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, groupId: groupId),
      body: groupId.isEmpty ? const _NoGroupState() : _buildBody(groupId),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required String groupId,
  }) {
    final isLoading =
        groupId.isNotEmpty && ref.watch(teamsProvider(groupId)).isLoading;

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
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppColors.info,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Equipos',
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
        else if (groupId.isNotEmpty)
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () =>
                ref.read(teamsProvider(groupId).notifier).refresh(),
            tooltip: 'Actualizar',
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(49),
        child: Column(
          children: [
            Container(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.4),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.labelLarge,
              tabs: groupId.isNotEmpty
                  ? _buildTabs(ref.watch(teamsProvider(groupId)))
                  : const [Tab(text: 'Alumnos'), Tab(text: 'Docentes')],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabs(TeamsState state) {
    return [
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alumnos'),
            if (state.status == TeamsStatus.success &&
                state.students.isNotEmpty) ...[
              const SizedBox(width: 6),
              _CountBubble(count: state.students.length),
            ],
          ],
        ),
      ),
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Docentes'),
            if (state.status == TeamsStatus.success &&
                state.teachers.isNotEmpty) ...[
              const SizedBox(width: 6),
              _CountBubble(count: state.teachers.length),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _buildBody(String groupId) {
    final state = ref.watch(teamsProvider(groupId));

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.hasError && state.students.isEmpty && state.teachers.isEmpty) {
      return _ErrorState(
        message: state.errorMessage,
        onRetry: () => ref.read(teamsProvider(groupId).notifier).refresh(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _StudentsTab(state: state),
        _TeachersTab(state: state),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab alumnos
// ---------------------------------------------------------------------------

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.state});

  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    if (state.students.isEmpty) {
      return const _EmptyList(
        icon: Icons.school_outlined,
        message: 'No hay alumnos disponibles en este grupo.',
        sub: 'Todos los alumnos ya tienen equipo asignado.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      itemCount: state.students.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => StudentCard(student: state.students[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab docentes
// ---------------------------------------------------------------------------

class _TeachersTab extends StatelessWidget {
  const _TeachersTab({required this.state});

  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    if (state.teachers.isEmpty) {
      return const _EmptyList(
        icon: Icons.person_outline_rounded,
        message: 'No hay docentes disponibles para este grupo.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      itemCount: state.teachers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => TeacherCard(teacher: state.teachers[i]),
    );
  }
}

// ---------------------------------------------------------------------------
// Burbuja de conteo
// ---------------------------------------------------------------------------

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Center(
        child: Text(
          '$count',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados vacíos
// ---------------------------------------------------------------------------

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.icon, required this.message, this.sub});

  final IconData icon;
  final String message;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 52),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                sub!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              message ?? 'Error al cargar el equipo.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            BifrostButton(
              label: 'Reintentar',
              onPressed: onRetry,
              variant: BifrostButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoGroupState extends StatelessWidget {
  const _NoGroupState();

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
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.group_outlined,
                color: AppColors.info,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sin grupo asignado',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Completa tu perfil para ver los equipos disponibles en tu grupo.',
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
