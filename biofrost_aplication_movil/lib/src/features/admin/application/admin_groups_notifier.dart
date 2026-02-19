import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/commands/create_group_command.dart';
import '../data/models/commands/update_group_command.dart';
import '../data/models/read/group_read_model.dart';
import '../data/repositories/admin_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminGroupsState {
  const AdminGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<GroupReadModel> groups;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AdminGroupsState copyWith({
    List<GroupReadModel>? groups,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// [Query] Notifier
// ---------------------------------------------------------------------------

class AdminGroupsNotifier extends StateNotifier<AdminGroupsState> {
  AdminGroupsNotifier(this._repo) : super(const AdminGroupsState());

  final IAdminRepository _repo;

  /// [Query] Carga lista de grupos con Stale-While-Revalidate.
  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final groups = await _repo.getGroups();
      state = state.copyWith(groups: groups, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
    }
  }

  /// [Command] Crear grupo con optimistic feedback.
  Future<void> createGroup(CreateGroupCommand cmd) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.createGroup(cmd);
      await loadGroups();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Grupo creado correctamente.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo crear el grupo.',
      );
    }
  }

  /// [Command] Actualizar grupo.
  Future<void> updateGroup(String id, UpdateGroupCommand cmd) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.updateGroup(id, cmd);
      await loadGroups();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Grupo actualizado.',
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo actualizar el grupo.',
      );
    }
  }

  /// [Command] Eliminar grupo (soft delete).
  Future<void> deleteGroup(String id) async {
    // Optimistic update — remove from list immediately
    final previous = state.groups;
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != id).toList(),
      errorMessage: null,
    );
    try {
      await _repo.deleteGroup(id);
      state = state.copyWith(successMessage: 'Grupo eliminado.');
    } on AppException catch (e) {
      // Rollback
      state = state.copyWith(groups: previous, errorMessage: e.userMessage);
    } catch (_) {
      state = state.copyWith(
        groups: previous,
        errorMessage: 'No se pudo eliminar el grupo.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final adminGroupsProvider =
    StateNotifierProvider<AdminGroupsNotifier, AdminGroupsState>((ref) {
      return AdminGroupsNotifier(ref.read(adminRepositoryProvider));
    });
