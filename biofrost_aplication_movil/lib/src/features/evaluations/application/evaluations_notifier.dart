import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/create_evaluation_command.dart';
import '../data/models/evaluation_read_model.dart';
import '../data/repositories/evaluations_repository.dart';

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

enum EvaluationsStatus { idle, loading, submitting, success, error }

class EvaluationsState {
  const EvaluationsState({
    this.status = EvaluationsStatus.idle,
    this.evaluations = const [],
    this.projectId = '',
    this.errorMessage,
    this.successMessage,
  });

  final EvaluationsStatus status;
  final List<EvaluationReadModel> evaluations;
  final String projectId;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == EvaluationsStatus.loading;
  bool get isSubmitting => status == EvaluationsStatus.submitting;
  bool get hasError => status == EvaluationsStatus.error;

  /// Promedio de calificaciones oficiales (null si no hay ninguna).
  double? get promedioOficial {
    final oficiales = evaluations
        .where((e) => e.isOficial && e.calificacion != null)
        .toList();
    if (oficiales.isEmpty) return null;
    final sum = oficiales.fold<int>(0, (acc, e) => acc + e.calificacion!);
    return sum / oficiales.length;
  }

  EvaluationsState copyWith({
    EvaluationsStatus? status,
    List<EvaluationReadModel>? evaluations,
    String? projectId,
    Object? errorMessage = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return EvaluationsState(
      status: status ?? this.status,
      evaluations: evaluations ?? this.evaluations,
      projectId: projectId ?? this.projectId,
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

class EvaluationsNotifier extends StateNotifier<EvaluationsState> {
  EvaluationsNotifier(this._repo, String projectId)
    : super(EvaluationsState(projectId: projectId)) {
    _load();
  }

  final IEvaluationsRepository _repo;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (state.projectId.isEmpty) return;
    state = state.copyWith(
      status: EvaluationsStatus.loading,
      errorMessage: null,
    );
    try {
      final list = await _repo.getByProject(state.projectId);
      // Orden descendente — más reciente primero
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(
        status: EvaluationsStatus.success,
        evaluations: list,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: EvaluationsStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: EvaluationsStatus.error,
        errorMessage: 'Error al cargar evaluaciones.',
      );
    }
  }

  Future<void> refresh() => _load();

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> submit(CreateEvaluationCommand command) async {
    if (!command.isValid) {
      state = state.copyWith(
        status: EvaluationsStatus.error,
        errorMessage: _validationError(command),
      );
      return;
    }

    state = state.copyWith(
      status: EvaluationsStatus.submitting,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _repo.create(command);
      state = state.copyWith(successMessage: 'Evaluación enviada.');
      await _load();
    } on AppException catch (e) {
      state = state.copyWith(
        status: EvaluationsStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: EvaluationsStatus.error,
        errorMessage: 'No se pudo enviar la evaluación.',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  String _validationError(CreateEvaluationCommand cmd) {
    if (cmd.contenido.trim().isEmpty)
      return 'El contenido no puede estar vacío.';
    if (cmd.tipo == 'oficial' && cmd.calificacion == null) {
      return 'Las evaluaciones oficiales requieren calificación.';
    }
    return 'Datos inválidos.';
  }
}

// ---------------------------------------------------------------------------
// Provider (family por projectId)
// ---------------------------------------------------------------------------

final evaluationsProvider =
    StateNotifierProvider.family<EvaluationsNotifier, EvaluationsState, String>(
      (ref, projectId) => EvaluationsNotifier(
        ref.read(evaluationsRepositoryProvider),
        projectId,
      ),
    );
