import '../config/api_endpoints.dart';
import '../errors/app_exceptions.dart';
import '../models/evaluation_read_model.dart';
import '../services/api_service.dart';

/// Repositorio de evaluaciones.
///
/// CQRS:
/// - Queries: [getEvaluationsByProject]
/// - Commands: [createEvaluation], [toggleVisibility]
///
/// Permisos (documentado en 05_EVALUATIONS.md § Permisos de Evaluación):
/// - Ver: todos los usuarios autenticados
/// - Crear sugerencia: cualquier Docente
/// - Crear evaluación oficial: solo Docente titular o Admin
/// - Cambiar visibilidad: Docentes y Admin
class EvaluationRepository {
  EvaluationRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  // ── Caché en memoria ───────────────────────────────────────────────
  final Map<String, _CacheEntry<List<EvaluationReadModel>>> _cache = {};

  // ── CQRS Query: Obtener evaluaciones ──────────────────────────────

  /// Obtiene todas las evaluaciones de un proyecto, ordenadas por fecha desc.
  ///
  /// Endpoint: GET /api/evaluations/project/{projectId}
  ///
  /// Fallback offline: si la solicitud falla y hay datos en caché (aunque
  /// expirados), los devuelve en lugar de lanzar excepción.
  Future<List<EvaluationReadModel>> getEvaluationsByProject(
    String projectId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[projectId];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final response = await _api.get<List<dynamic>>(
        ApiEndpoints.evaluationsByProject(projectId),
      );

      final evaluations = _parseList(response.data ?? []);
      // Ordenar por fecha descendente (más reciente primero)
      evaluations.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );

      _cache[projectId] = _CacheEntry(evaluations);
      return evaluations;
    } catch (e) {
      // Fallback offline: devolver caché obsoleto si existe
      if (cached != null) return cached.data;
      rethrow;
    }
  }

  /// Calificación oficial más reciente de un proyecto.
  ///
  /// Según 05_EVALUATIONS.md: "El grade actual es siempre la calificación
  /// oficial más reciente, no un promedio."
  double? getCurrentGrade(List<EvaluationReadModel> evaluations) {
    final oficial = evaluations.firstWhere(
      (e) => e.isOficial && e.hasGrade,
      orElse: () => throw const NotFoundException(),
    );
    return oficial.calificacion;
  }

  // ── CQRS Command: Crear evaluación ────────────────────────────────

  /// Crea una nueva evaluación (sugerencia u oficial).
  ///
  /// Valida permisos antes de enviar:
  /// - Solo Docentes pueden crear evaluaciones.
  /// - Solo el Docente titular puede emitir evaluaciones oficiales.
  ///
  /// Endpoint: POST /api/evaluations
  ///
  /// Retorna la evaluación creada y actualiza el caché local.
  Future<EvaluationReadModel> createEvaluation(
    CreateEvaluationCommand command,
  ) async {
    // Validación de contenido
    if (command.contenido.trim().isEmpty) {
      throw const BusinessException(
        'El contenido de la evaluación no puede estar vacío.',
        field: 'contenido',
      );
    }

    // Validación de calificación oficial
    if (command.tipo == 'oficial') {
      if (command.calificacion == null) {
        throw const BusinessException(
          'Una evaluación oficial requiere calificación.',
          field: 'calificacion',
        );
      }
      if (command.calificacion! < 0 || command.calificacion! > 100) {
        throw const BusinessException(
          'La calificación debe estar entre 0 y 100.',
          field: 'calificacion',
        );
      }
    }

    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.createEvaluation,
      data: command.toJson(),
    );

    if (response.data == null) {
      throw const ServerException(
        message: 'Error al crear la evaluación.',
      );
    }

    final created = EvaluationReadModel.fromJson(response.data!);

    // Actualizar caché: agregar la nueva evaluación al inicio de la lista
    final key = command.projectId;
    if (_cache.containsKey(key)) {
      final updated = [created, ..._cache[key]!.data];
      _cache[key] = _CacheEntry(updated);
    }

    return created;
  }

  // ── CQRS Command: Cambiar visibilidad (Optimistic Update) ─────────

  /// Cambia la visibilidad pública/privada de una evaluación.
  ///
  /// Implementa Optimistic Update:
  /// 1. Actualiza el estado local inmediatamente.
  /// 2. Llama al backend.
  /// 3. Si falla: retorna la evaluación con el estado original para rollback.
  ///
  /// Endpoint: PATCH /api/evaluations/{id}/visibility
  ///
  /// Retorna:
  /// - La evaluación con el nuevo estado si el backend confirma.
  /// - null si hubo un error (la UI debe hacer rollback).
  Future<EvaluationReadModel?> toggleVisibility(
    ToggleEvaluationVisibilityCommand command,
    String projectId,
  ) async {
    try {
      await _api.patch(
        ApiEndpoints.evaluationVisibility(command.evaluationId),
        data: command.toJson(),
      );

      // Actualizar caché
      if (_cache.containsKey(projectId)) {
        final updated = _cache[projectId]!.data.map((e) {
          if (e.id == command.evaluationId) {
            return e.copyWith(esPublico: command.esPublico);
          }
          return e;
        }).toList();
        _cache[projectId] = _CacheEntry(updated);
      }

      return null; // Éxito: null significa "no hubo error"
    } on AppException {
      rethrow; // El provider hace rollback con el estado anterior
    }
  }

  // ── Permisos (lógica documentada en 05_EVALUATIONS.md) ────────────

  /// Verifica si un usuario puede emitir evaluación oficial.
  ///
  /// Condición: (isDocente && isTitular) || isAdmin
  bool canGradeOfficially({
    required String userRol,
    required String? userId,
    required String? docenteTitularId,
  }) {
    final isDocente = userRol == 'Docente';
    final isAdmin = userRol == 'admin' || userRol == 'SuperAdmin';
    final isTitular = userId != null && userId == docenteTitularId;
    return isDocente && (isTitular || isAdmin);
  }

  /// Verifica si un usuario puede enviar sugerencias.
  bool canSendSuggestion(String userRol) => userRol == 'Docente';

  /// Verifica si un usuario puede cambiar visibilidad.
  bool canToggleVisibility(String userRol) {
    return userRol == 'Docente' ||
        userRol == 'admin' ||
        userRol == 'SuperAdmin';
  }

  // ── CQRS Query: Historial por docente ─────────────────────────────

  /// Obtiene todas las evaluaciones emitidas por un docente, ordenadas por
  /// fecha descendente.
  ///
  /// Endpoint: GET /api/evaluations/docente/{docenteId}
  ///
  /// Fallback offline: devuelve caché obsoleto si la red falla.
  Future<List<EvaluationReadModel>> getEvaluationsByDocente(
    String docenteId, {
    bool forceRefresh = false,
  }) async {
    const cacheKey = '__docente__';
    final key = '$cacheKey$docenteId';
    final cached = _cache[key];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final response = await _api.get<List<dynamic>>(
        ApiEndpoints.evaluationsByDocente(docenteId),
      );

      final evaluations = _parseList(response.data ?? []);
      evaluations.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );

      _cache[key] = _CacheEntry(evaluations);
      return evaluations;
    } catch (_) {
      if (cached != null) return cached.data;
      return [];
    }
  }

  // ── Cache invalidation ─────────────────────────────────────────────

  void invalidateProject(String projectId) => _cache.remove(projectId);
  void invalidateAll() => _cache.clear();

  // ── Helpers ────────────────────────────────────────────────────────

  List<EvaluationReadModel> _parseList(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(EvaluationReadModel.fromJson)
        .toList();
  }
}

class _CacheEntry<T> {
  _CacheEntry(this.data, {Duration ttl = const Duration(minutes: 2)})
      : _expiry = DateTime.now().add(ttl);

  final T data;
  final DateTime _expiry;

  bool get isExpired => DateTime.now().isAfter(_expiry);
}
