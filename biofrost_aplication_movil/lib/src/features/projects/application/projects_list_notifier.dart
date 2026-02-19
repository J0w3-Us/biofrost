import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/project_list_item_model.dart';
import '../data/repositories/projects_repository.dart';
import '../data/repositories/cached_projects_repository.dart';

// ---------------------------------------------------------------------------
// Estado — lista de proyectos (grupo o públicos)
// ---------------------------------------------------------------------------

enum ProjectsListMode { group, public }

enum ProjectsListStatus { idle, loading, loaded, error }

class ProjectsListState {
  const ProjectsListState({
    this.status = ProjectsListStatus.idle,
    this.mode = ProjectsListMode.group,
    this.projects = const [],
    this.errorMessage,
  });

  final ProjectsListStatus status;
  final ProjectsListMode mode;
  final List<ProjectListItemModel> projects;
  final String? errorMessage;

  bool get isLoading => status == ProjectsListStatus.loading;
  bool get hasError => status == ProjectsListStatus.error;

  ProjectsListState copyWith({
    ProjectsListStatus? status,
    ProjectsListMode? mode,
    List<ProjectListItemModel>? projects,
    Object? errorMessage = _sentinel,
  }) {
    return ProjectsListState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      projects: projects ?? this.projects,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _sentinel = Object();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProjectsListNotifier extends StateNotifier<ProjectsListState> {
  ProjectsListNotifier(this._repo, this._groupId)
    : super(const ProjectsListState()) {
    loadGroup();
  }

  final IProjectsRepository _repo;
  final String _groupId;

  // ── Cargar lista del grupo ─────────────────────────────────────────────────

  Future<void> loadGroup() async {
    state = state.copyWith(
      status: ProjectsListStatus.loading,
      mode: ProjectsListMode.group,
    );
    try {
      final items = await _repo.getByGroup(_groupId);
      state = state.copyWith(
        status: ProjectsListStatus.loaded,
        projects: items,
      );
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectsListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Cargar proyectos públicos ─────────────────────────────────────────────

  Future<void> loadPublic() async {
    state = state.copyWith(
      status: ProjectsListStatus.loading,
      mode: ProjectsListMode.public,
    );
    try {
      final items = await _repo.getPublicProjects();
      state = state.copyWith(
        status: ProjectsListStatus.loaded,
        projects: items,
      );
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectsListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider — familia por groupId
// ---------------------------------------------------------------------------

final projectsListProvider =
    StateNotifierProvider.family<
      ProjectsListNotifier,
      ProjectsListState,
      String
    >((ref, groupId) {
      return ProjectsListNotifier(
        ref.read(projectsRepositoryProvider),
        groupId,
      );
    });
