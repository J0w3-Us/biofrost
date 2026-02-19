import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/add_member_command.dart';
import '../data/models/project_detail_model.dart';
import '../data/models/update_project_command.dart';
import '../data/repositories/projects_repository.dart';
import '../data/repositories/cached_projects_repository.dart';
import '../../showcase/data/models/canvas_block_model.dart';

// ---------------------------------------------------------------------------
// Estado — detalle de un proyecto
// ---------------------------------------------------------------------------

enum ProjectDetailStatus { idle, loading, loaded, submitting, success, error }

class ProjectDetailState {
  const ProjectDetailState({
    this.status = ProjectDetailStatus.idle,
    this.project,
    this.errorMessage,
    this.successMessage,
  });

  final ProjectDetailStatus status;
  final ProjectDetailModel? project;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == ProjectDetailStatus.loading;
  bool get isSubmitting => status == ProjectDetailStatus.submitting;
  bool get hasError => status == ProjectDetailStatus.error;
  bool get hasProject => project != null;

  ProjectDetailState copyWith({
    ProjectDetailStatus? status,
    ProjectDetailModel? project,
    Object? errorMessage = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return ProjectDetailState(
      status: status ?? this.status,
      project: project ?? this.project,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
    );
  }

  static const _sentinel = Object();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProjectDetailNotifier extends StateNotifier<ProjectDetailState> {
  ProjectDetailNotifier(this._repo, this._projectId)
    : super(const ProjectDetailState()) {
    load();
  }

  final IProjectsRepository _repo;
  final String _projectId;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(status: ProjectDetailStatus.loading);
    try {
      final project = await _repo.getById(_projectId);
      state = state.copyWith(
        status: ProjectDetailStatus.loaded,
        project: project,
      );
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> update(UpdateProjectCommand command) async {
    state = state.copyWith(status: ProjectDetailStatus.submitting);
    try {
      await _repo.update(_projectId, command);
      await load();
      state = state.copyWith(successMessage: 'Proyecto actualizado');
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Canvas ────────────────────────────────────────────────────────────────

  Future<void> saveCanvas(List<CanvasBlockModel> blocks, String userId) async {
    state = state.copyWith(status: ProjectDetailStatus.submitting);
    try {
      await _repo.updateCanvas(_projectId, blocks, userId);
      await load();
      state = state.copyWith(successMessage: 'Canvas guardado');
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Members ───────────────────────────────────────────────────────────────

  Future<bool> addMember(AddMemberCommand command) async {
    state = state.copyWith(status: ProjectDetailStatus.submitting);
    try {
      await _repo.addMember(_projectId, command);
      await load();
      state = state.copyWith(successMessage: 'Miembro agregado');
      return true;
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> removeMember(String memberId, String requestingUserId) async {
    state = state.copyWith(status: ProjectDetailStatus.submitting);
    try {
      await _repo.removeMember(_projectId, memberId, requestingUserId);
      await load();
      state = state.copyWith(successMessage: 'Miembro eliminado');
      return true;
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteProject(String requestingUserId) async {
    state = state.copyWith(status: ProjectDetailStatus.submitting);
    try {
      await _repo.delete(_projectId, requestingUserId);
      return true;
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ---------------------------------------------------------------------------
// Notifier — "mi proyecto" (por userId)
// ---------------------------------------------------------------------------

class MyProjectNotifier extends StateNotifier<ProjectDetailState> {
  MyProjectNotifier(this._repo, this._userId)
    : super(const ProjectDetailState()) {
    load();
  }

  final IProjectsRepository _repo;
  final String _userId;

  Future<void> load() async {
    state = state.copyWith(status: ProjectDetailStatus.loading);
    try {
      final project = await _repo.getMyProject(_userId);
      state = state.copyWith(
        status: ProjectDetailStatus.loaded,
        project: project,
      );
    } on Object catch (e) {
      state = state.copyWith(
        status: ProjectDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final projectDetailProvider =
    StateNotifierProvider.family<
      ProjectDetailNotifier,
      ProjectDetailState,
      String
    >((ref, projectId) {
      return ProjectDetailNotifier(
        ref.read(projectsRepositoryProvider),
        projectId,
      );
    });

final myProjectProvider =
    StateNotifierProvider.family<MyProjectNotifier, ProjectDetailState, String>(
      (ref, userId) {
        return MyProjectNotifier(ref.read(projectsRepositoryProvider), userId);
      },
    );
