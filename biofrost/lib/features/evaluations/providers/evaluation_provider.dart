import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/features/evaluations/data/evaluation_repository.dart';
import 'package:biofrost/features/evaluations/domain/commands/evaluation_commands.dart';
import 'package:biofrost/features/evaluations/domain/models/evaluation_read_model.dart';
import 'package:biofrost/core/services/analytics_service.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';

// ── Estado del panel de evaluaciones ───────────────────────────────────

/// Estado del panel de evaluaciones de un proyecto.
class EvaluationPanelState {
  const EvaluationPanelState({
    this.evaluations = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitError,
    // Form state
    this.tipo = 'sugerencia',
    this.contenido = '',
    this.calificacion = 80.0,
  });

  final List<EvaluationReadModel> evaluations;
  final bool isLoading;

  /// True mientras se envía una nueva evaluación al backend.
  final bool isSubmitting;
  final AppException? error;

  /// Error específico del formulario de envío.
  final AppException? submitError;

  // ── Estado del formulario ────────────────────────────────────────────
  /// 'sugerencia' | 'oficial'
  final String tipo;
  final String contenido;

  /// Valor del slider de calificación (0-100). Default: 80.
  final double calificacion;

  // ── Computed ────────────────────────────────────────────────────────

  bool get hasError => error != null;
  bool get hasSubmitError => submitError != null;

  /// Calificación oficial más reciente del proyecto.
  double? get currentGrade {
    try {
      return evaluations
          .firstWhere((e) => e.isOficial && e.hasGrade)
          .calificacion;
    } catch (_) {
      return null;
    }
  }

  /// El formulario es válido para enviar.
  bool get isFormValid =>
      contenido.trim().isNotEmpty &&
      (tipo == 'sugerencia' || (tipo == 'oficial' && calificacion >= 0));

  EvaluationPanelState copyWith({
    List<EvaluationReadModel>? evaluations,
    bool? isLoading,
    bool? isSubmitting,
    AppException? error,
    bool clearError = false,
    AppException? submitError,
    bool clearSubmitError = false,
    String? tipo,
    String? contenido,
    double? calificacion,
  }) {
    return EvaluationPanelState(
      evaluations: evaluations ?? this.evaluations,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      tipo: tipo ?? this.tipo,
      contenido: contenido ?? this.contenido,
      calificacion: calificacion ?? this.calificacion,
    );
  }
}

// ── Notifier del Panel de Evaluaciones ─────────────────────────────────

/// Gestiona el estado completo del panel de evaluaciones de un proyecto.
///
/// CQRS:
/// - [load] → GET /api/evaluations/project/{id} (Query)
/// - [submitEvaluation] → POST /api/evaluations (Command)
/// - [toggleVisibility] → PATCH /api/evaluations/{id}/visibility (Command + Optimistic Update)
///
/// Acceso: Docentes, Evaluadores e Invitados autenticados.
class EvaluationPanelNotifier
    extends FamilyNotifier<EvaluationPanelState, String> {
  @override
  EvaluationPanelState build(String projectId) {
    Future.microtask(() => load(projectId));
    return const EvaluationPanelState(isLoading: true);
  }

  EvaluationRepository get _repo => ref.read(evaluationRepositoryProvider);

  // ── CQRS Query ───────────────────────────────────────────────────────

  Future<void> load(String projectId, {bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final evaluations = await _repo.getEvaluationsByProject(
        projectId,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        evaluations: evaluations,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ── Form updates ─────────────────────────────────────────────────────

  void setTipo(String tipo) => state = state.copyWith(tipo: tipo);
  void setContenido(String contenido) =>
      state = state.copyWith(contenido: contenido, clearSubmitError: true);
  void setCalificacion(double value) =>
      state = state.copyWith(calificacion: value);

  void resetForm() => state = state.copyWith(
        tipo: 'sugerencia',
        contenido: '',
        calificacion: 80.0,
        clearSubmitError: true,
      );

  // ── CQRS Command: Crear evaluación ─────────────────────────────────

  /// Envía una nueva evaluación al backend.
  ///
  /// Verifica permisos antes de enviar:
  /// - Docentes, Evaluadores e Invitados pueden crear sugerencias.
  /// - Solo el Docente titular puede emitir evaluaciones oficiales.
  ///
  /// Actualiza la lista local inmediatamente al recibir respuesta.
  Future<bool> submitEvaluation({
    required String projectId,
    required String docenteId,
    required String docenteNombre,
    required String? docenteTitularId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw const AuthException();

    // Validar permiso para tipo 'oficial'
    if (state.tipo == 'oficial') {
      final canGrade = _repo.canGradeOfficially(
        userRol: user.rol,
        userId: user.userId,
        docenteTitularId: docenteTitularId,
      );
      if (!canGrade) {
        state = state.copyWith(
          submitError: const ForbiddenException(
            message:
                'Solo el docente titular puede emitir evaluaciones oficiales.',
          ),
        );
        return false;
      }
    }

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    try {
      final command = CreateEvaluationCommand(
        projectId: projectId,
        docenteId: docenteId,
        docenteNombre: docenteNombre,
        tipo: state.tipo,
        contenido: state.contenido,
        calificacion: state.tipo == 'oficial' ? state.calificacion : null,
      );

      final created = await _repo.createEvaluation(command);

      // Agregar al inicio de la lista (más reciente primero)
      final updated = [created, ...state.evaluations];
      state = state.copyWith(
        evaluations: updated,
        isSubmitting: false,
      );

      resetForm();

      // Analytics: registrar envío
      ref.read(analyticsServiceProvider).trackEvaluationSubmit(command.tipo);

      return true;
    } on BusinessException catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e);
      return false;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e);
      return false;
    }
  }

  // ── CQRS Command: Toggle visibilidad (Optimistic Update) ───────────

  /// Cambia la visibilidad de una evaluación con actualización optimista.
  ///
  /// 1. Actualiza el estado local inmediatamente (UI responde al instante).
  /// 2. Llama al backend.
  /// 3. Si falla: revierte al estado anterior.
  Future<void> toggleVisibility(
    EvaluationReadModel evaluation,
    String userId,
    String projectId,
  ) async {
    // Verificar permiso
    final user = ref.read(currentUserProvider);
    if (user == null || !_repo.canToggleVisibility(user.rol)) {
      return;
    }

    // Estado anterior para rollback
    final previousEvaluations = state.evaluations;

    // 1. Optimistic update: cambiar visibilidad localmente
    final newEsPublico = !evaluation.esPublico;
    final updatedList = state.evaluations.map((e) {
      return e.id == evaluation.id ? e.copyWith(esPublico: newEsPublico) : e;
    }).toList();

    state = state.copyWith(evaluations: updatedList);

    // 2. Llamada al backend
    try {
      final command = ToggleEvaluationVisibilityCommand(
        evaluationId: evaluation.id,
        userId: userId,
        esPublico: newEsPublico,
      );
      await _repo.toggleVisibility(command, projectId);
    } on AppException {
      // 3. Rollback si falla
      state = state.copyWith(evaluations: previousEvaluations);
    }
  }
}

/// Provider parametrado por projectId.
final evaluationPanelProvider = NotifierProviderFamily<EvaluationPanelNotifier,
    EvaluationPanelState, String>(
  EvaluationPanelNotifier.new,
);

// ── Provider: Historial de evaluaciones por docente ─────────────────────

/// Carga el historial completo de evaluaciones emitidas por un docente.
///
/// Endpoint: GET /api/evaluations/docente/{docenteId}
/// Usado en [ProfilePage] para mostrar el historial del docente autenticado.
final docenteEvaluationHistoryProvider =
    FutureProvider.family<List<EvaluationReadModel>, String>(
  (ref, docenteId) {
    final repo = ref.read(evaluationRepositoryProvider);
    return repo.getEvaluationsByDocente(docenteId);
  },
);
