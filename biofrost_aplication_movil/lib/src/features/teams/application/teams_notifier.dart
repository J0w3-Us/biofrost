import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/student_read_model.dart';
import '../data/models/teacher_read_model.dart';
import '../data/repositories/teams_repository.dart';

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

enum TeamsStatus { idle, loading, success, error }

class TeamsState {
  const TeamsState({
    this.status = TeamsStatus.idle,
    this.students = const [],
    this.teachers = const [],
    this.groupId = '',
    this.errorMessage,
  });

  final TeamsStatus status;
  final List<StudentReadModel> students;
  final List<TeacherReadModel> teachers;
  final String groupId;
  final String? errorMessage;

  bool get isLoading => status == TeamsStatus.loading;
  bool get hasError => status == TeamsStatus.error;

  /// Docentes de alta prioridad (materia integradora) — mostrados primero.
  List<TeacherReadModel> get altaPrioridad =>
      teachers.where((t) => t.esAltaPrioridad).toList();

  List<TeacherReadModel> get otrosDocentes =>
      teachers.where((t) => !t.esAltaPrioridad).toList();

  TeamsState copyWith({
    TeamsStatus? status,
    List<StudentReadModel>? students,
    List<TeacherReadModel>? teachers,
    String? groupId,
    Object? errorMessage = _sentinel,
  }) {
    return TeamsState(
      status: status ?? this.status,
      students: students ?? this.students,
      teachers: teachers ?? this.teachers,
      groupId: groupId ?? this.groupId,
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

class TeamsNotifier extends StateNotifier<TeamsState> {
  TeamsNotifier(this._repo, String groupId)
    : super(TeamsState(groupId: groupId)) {
    if (groupId.isNotEmpty) _load();
  }

  final ITeamsRepository _repo;

  Future<void> _load() async {
    state = state.copyWith(status: TeamsStatus.loading, errorMessage: null);
    try {
      // Carga en paralelo
      final results = await Future.wait([
        _repo.getAvailableStudents(state.groupId),
        _repo.getAvailableTeachers(state.groupId),
      ]);

      final students = results[0] as List<StudentReadModel>;
      final teachers = results[1] as List<TeacherReadModel>;

      // Alta prioridad primero (ya viene ordenado del backend, pero lo
      // reforzamos por si acaso)
      teachers.sort((a, b) {
        if (a.esAltaPrioridad == b.esAltaPrioridad) {
          return a.nombreCompleto.compareTo(b.nombreCompleto);
        }
        return a.esAltaPrioridad ? -1 : 1;
      });

      state = state.copyWith(
        status: TeamsStatus.success,
        students: students,
        teachers: teachers,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: TeamsStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: TeamsStatus.error,
        errorMessage: 'Error al cargar datos del equipo.',
      );
    }
  }

  Future<void> refresh() => _load();
}

// ---------------------------------------------------------------------------
// Provider (family por groupId)
// ---------------------------------------------------------------------------

final teamsProvider =
    StateNotifierProvider.family<TeamsNotifier, TeamsState, String>(
      (ref, groupId) =>
          TeamsNotifier(ref.read(teamsRepositoryProvider), groupId),
    );
