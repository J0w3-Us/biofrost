import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui_kit.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/project_detail_notifier.dart';
import '../application/projects_list_notifier.dart';
import '../data/models/project_detail_model.dart';
import '../data/models/project_list_item_model.dart';
import 'project_create_page.dart';
import 'project_detail_page.dart';
import 'widgets/project_list_card.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  static const routeName = '/projects';

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage>
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
    final isAlumno = user?.isAlumno ?? false;
    final groupId = user?.grupoId ?? '';
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.20),
                AppColors.surface,
              ],
            ),
          ),
        ),
        title: const Text(
          'Proyectos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppTextStyles.label,
                tabs: [
                  const Tab(text: 'Mi Proyecto'),
                  if (isAlumno || (user?.isDocente ?? false))
                    const Tab(text: 'Grupo'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (isAlumno)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
              onPressed: () =>
                  Navigator.of(context).pushNamed(ProjectCreatePage.routeName),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyProjectTab(userId: userId),
          _GroupProjectsTab(groupId: groupId),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab — Mi Proyecto
// ---------------------------------------------------------------------------

class _MyProjectTab extends ConsumerWidget {
  const _MyProjectTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return const _EmptyState(message: 'No hay sesión activa');
    }
    final state = ref.watch(myProjectProvider(userId));

    if (state.isLoading) {
      return const ShimmerCardList(count: 3);
    }

    if (state.hasError) {
      return _ErrorState(
        message: state.errorMessage ?? 'Error al cargar',
        onRetry: () => ref.read(myProjectProvider(userId).notifier).load(),
      );
    }

    if (!state.hasProject) {
      return _EmptyState(
        message: 'Aún no tienes un proyecto asignado',
        icon: Icons.rocket_launch_rounded,
        action: ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Crear Proyecto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.of(context).pushNamed(ProjectCreatePage.routeName),
        ),
      );
    }

    final project = state.project!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProjectListCard(
            project: _projectToListItem(project),
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ProjectDetailPage.routeName, arguments: project.id),
          ),
          const SizedBox(height: AppSpacing.md),
          BifrostButton(
            label: 'Ver detalle completo',
            icon: Icons.open_in_new_rounded,
            variant: BifrostButtonVariant.secondary,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(ProjectDetailPage.routeName, arguments: project.id),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab — Proyectos del Grupo
// ---------------------------------------------------------------------------

class _GroupProjectsTab extends ConsumerWidget {
  const _GroupProjectsTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupId.isEmpty) {
      return const _EmptyState(message: 'Sin grupo asignado');
    }
    final state = ref.watch(projectsListProvider(groupId));

    if (state.isLoading) {
      return const ShimmerCardList(count: 4);
    }

    if (state.hasError) {
      return _ErrorState(
        message: state.errorMessage ?? 'Error al cargar',
        onRetry: () =>
            ref.read(projectsListProvider(groupId).notifier).loadGroup(),
      );
    }

    if (state.projects.isEmpty) {
      return const _EmptyState(
        message: 'No hay proyectos en este grupo',
        icon: Icons.folder_open_rounded,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(projectsListProvider(groupId).notifier).loadGroup(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: state.projects.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final project = state.projects[index];
          return ProjectListCard(
            project: project,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(ProjectDetailPage.routeName, arguments: project.id),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Convierte ProjectDetailModel → ProjectListItemModel para el card
ProjectListItemModel _projectToListItem(ProjectDetailModel p) {
  return ProjectListItemModel(
    id: p.id,
    titulo: p.titulo,
    materia: p.materia,
    estado: p.estado,
    stackTecnologico: p.stackTecnologico,
    liderId: p.liderId,
    membersCount: p.miembrosIds.length,
    repositorioUrl: p.repositorioUrl,
    videoUrl: p.videoUrl,
    ciclo: p.ciclo,
  );
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            BifrostButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              variant: BifrostButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
