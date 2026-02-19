import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/create_carrera_command.dart';
import '../data/models/read/carrera_read_model.dart';
import '../data/repositories/admin_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminCarrerasState {
  const AdminCarrerasState({
    this.carreras = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<CarreraReadModel> carreras;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AdminCarrerasState copyWith({
    List<CarreraReadModel>? carreras,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminCarrerasState(
      carreras: carreras ?? this.carreras,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// [Query + Command] Notifier
// ---------------------------------------------------------------------------

class AdminCarrerasNotifier extends StateNotifier<AdminCarrerasState> {
  AdminCarrerasNotifier(this._repo) : super(const AdminCarrerasState());

  final IAdminRepository _repo;

  /// [Query] Carga todas las carreras.
  Future<void> loadCarreras() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final carreras = await _repo.getCarreras();
      state = state.copyWith(carreras: carreras, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al cargar carreras.',
      );
    }
  }

  /// [Command] Crear carrera.
  Future<void> createCarrera(CreateCarreraCommand cmd) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.createCarrera(cmd);
      await loadCarreras();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Carrera creada correctamente.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo crear la carrera.',
      );
    }
  }

  /// [Command] Eliminar carrera con optimistic update.
  Future<void> deleteCarrera(String id) async {
    final previous = state.carreras;
    state = state.copyWith(
      carreras: state.carreras.where((c) => c.id != id).toList(),
      errorMessage: null,
    );
    try {
      await _repo.deleteCarrera(id);
      state = state.copyWith(successMessage: 'Carrera eliminada.');
    } on AppException catch (e) {
      state = state.copyWith(carreras: previous, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        carreras: previous,
        errorMessage: 'No se pudo eliminar la carrera.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final adminCarrerasProvider =
    StateNotifierProvider<AdminCarrerasNotifier, AdminCarrerasState>((ref) {
      return AdminCarrerasNotifier(ref.read(adminRepositoryProvider));
    });
