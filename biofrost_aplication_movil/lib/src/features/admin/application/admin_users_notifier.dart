import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/update_student_group_command.dart';
import '../data/models/commands/update_teacher_assignments_command.dart';
import '../data/models/read/user_read_model.dart';
import '../data/repositories/admin_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminUsersState {
  const AdminUsersState({
    this.students = const [],
    this.teachers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<UserReadModel> students;
  final List<UserReadModel> teachers;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AdminUsersState copyWith({
    List<UserReadModel>? students,
    List<UserReadModel>? teachers,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminUsersState(
      students: students ?? this.students,
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// [Query + Command] Notifier
// ---------------------------------------------------------------------------

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  AdminUsersNotifier(this._repo) : super(const AdminUsersState());

  final IAdminRepository _repo;

  /// [Query] Carga lista de alumnos, filtrable por grupo.
  Future<void> loadStudents({String? grupoId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final students = await _repo.getStudents(grupoId: grupoId);
      state = state.copyWith(students: students, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar alumnos.',
      );
    }
  }

  /// [Query] Carga lista de docentes.
  Future<void> loadTeachers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final teachers = await _repo.getTeachers();
      state = state.copyWith(teachers: teachers, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar docentes.',
      );
    }
  }

  /// [Command] Actualizar grupo de un alumno.
  Future<void> updateStudentGroup(
    String userId,
    UpdateStudentGroupCommand cmd,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.updateStudentGroup(userId, cmd);
      await loadStudents();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Grupo del alumno actualizado.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo actualizar el grupo del alumno.',
      );
    }
  }

  /// [Command] Actualizar asignaciones de docente.
  Future<void> updateTeacherAssignments(
    String userId,
    UpdateTeacherAssignmentsCommand cmd,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.updateTeacherAssignments(userId, cmd);
      await loadTeachers();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Asignaciones del docente actualizadas.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo actualizar las asignaciones.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
      return AdminUsersNotifier(ref.read(adminRepositoryProvider));
    });
