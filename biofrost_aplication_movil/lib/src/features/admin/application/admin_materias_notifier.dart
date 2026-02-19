import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/create_materia_command.dart';
import '../data/models/read/materia_read_model.dart';
import '../data/repositories/admin_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminMateriasState {
  const AdminMateriasState({
    this.materias = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<MateriaReadModel> materias;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AdminMateriasState copyWith({
    List<MateriaReadModel>? materias,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminMateriasState(
      materias: materias ?? this.materias,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// [Query + Command] Notifier
// ---------------------------------------------------------------------------

class AdminMateriasNotifier extends StateNotifier<AdminMateriasState> {
  AdminMateriasNotifier(this._repo) : super(const AdminMateriasState());

  final IAdminRepository _repo;

  /// [Query] Carga materias, opcionalmente filtradas por carrera.
  Future<void> loadMaterias({String? carreraId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final materias = carreraId != null
          ? await _repo.getMateriasByCarrera(carreraId)
          : await _repo.getMaterias();
      state = state.copyWith(materias: materias, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar materias.',
      );
    }
  }

  /// [Command] Crear materia.
  Future<void> createMateria(CreateMateriaCommand cmd) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.createMateria(cmd);
      await loadMaterias();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Materia creada correctamente.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo crear la materia.',
      );
    }
  }

  /// [Command] Actualizar materia.
  Future<void> updateMateria(String id, CreateMateriaCommand cmd) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.updateMateria(id, cmd);
      await loadMaterias();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Materia actualizada.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo actualizar la materia.',
      );
    }
  }

  /// [Command] Eliminar materia (soft delete) con optimistic update.
  Future<void> deleteMateria(String id) async {
    final previous = state.materias;
    state = state.copyWith(
      materias: state.materias.where((m) => m.id != id).toList(),
      errorMessage: null,
    );
    try {
      await _repo.deleteMateria(id);
      state = state.copyWith(successMessage: 'Materia eliminada.');
    } on AppException catch (e) {
      state = state.copyWith(materias: previous, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        materias: previous,
        errorMessage: 'No se pudo eliminar la materia.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final adminMateriasProvider =
    StateNotifierProvider<AdminMateriasNotifier, AdminMateriasState>((ref) {
      return AdminMateriasNotifier(ref.read(adminRepositoryProvider));
    });
