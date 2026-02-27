import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/config/api_endpoints.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/services/api_service.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/evaluations/domain/commands/evaluation_commands.dart';
import 'package:biofrost/features/evaluations/domain/models/evaluation_read_model.dart';

/// Repositorio de evaluaciones — CQRS (Queries + Commands).
///
/// Permisos (documentado en 05_EVALUATIONS.md):
/// - Ver: todos los usuarios autenticados
/// - Crear sugerencia: Docente, Evaluador, Invitado
/// - Crear evaluación oficial: solo Docente titular o Admin
/// - Cambiar visibilidad: Docentes y Admin
class EvaluationRepository {
  EvaluationRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  // ── Caché en memoria ───────────────────────────────────────────────
  final Map<String, _CacheEntry<List<EvaluationReadModel>>> _cache = {};

  // ── CQRS Query: Obtener evaluaciones ──────────────────────────────

  /// GET /api/evaluations/project/{projectId}
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
      evaluations.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );

      _cache[projectId] = _CacheEntry(evaluations);
      return evaluations;
    } catch (e) {
      if (cached != null) return cached.data;
      rethrow;
    }
  }

  /// Calificación oficial más reciente de un proyecto.
  double? getCurrentGrade(List<EvaluationReadModel> evaluations) {
    try {
      return evaluations
          .firstWhere((e) => e.isOficial && e.hasGrade)
          .calificacion;
    } catch (_) {
      return null;
    }
  }

  // ── CQRS Command: Crear evaluación ────────────────────────────────

  /// POST /api/evaluations
  Future<EvaluationReadModel> createEvaluation(
    CreateEvaluationCommand command,
  ) async {
    if (command.contenido.trim().isEmpty) {
      throw const BusinessException(
        'El contenido de la evaluación no puede estar vacío.',
        field: 'contenido',
      );
    }

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
      throw const ServerException(message: 'Error al crear la evaluación.');
    }

    final created = EvaluationReadModel.fromJson(response.data!);

    // Actualizar caché
    final key = command.projectId;
    if (_cache.containsKey(key)) {
      final updated = [created, ..._cache[key]!.data];
      _cache[key] = _CacheEntry(updated);
    }

    return created;
  }

  // ── CQRS Command: Cambiar visibilidad (Optimistic Update) ─────────

  /// PATCH /api/evaluations/{id}/visibility
  ///
  /// Retorna null en éxito. La UI hace rollback si se lanza excepción.
  Future<void> toggleVisibility(
    ToggleEvaluationVisibilityCommand command,
    String projectId,
  ) async {
    await _api.patch(
      ApiEndpoints.evaluationVisibility(command.evaluationId),
      data: command.toJson(),
    );

    // Actualizar caché local
    if (_cache.containsKey(projectId)) {
      final updated = _cache[projectId]!.data.map((e) {
        if (e.id == command.evaluationId) {
          return e.copyWith(esPublico: command.esPublico);
        }
        return e;
      }).toList();
      _cache[projectId] = _CacheEntry(updated);
    }
  }

  // ── CQRS Query: Historial por docente ─────────────────────────────

  /// Filtra evaluaciones del caché local por docenteId.
  /// No existe endpoint backend dedicado; filtra desde caché en memoria.
  Future<List<EvaluationReadModel>> getEvaluationsByDocente(
    String docenteId,
  ) async {
    final all = _cache.values
        .expand((entry) => entry.data)
        .where((e) => e.docenteId == docenteId)
        .toList();

    all.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );

    return all;
  }

  // ── Permisos ───────────────────────────────────────────────────────

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

  bool canSendSuggestion(String userRol) => 
      userRol == 'Docente' || userRol == 'Evaluador' || userRol == 'Invitado';

  bool canToggleVisibility(String userRol) {
    return userRol == 'Docente' ||
        userRol == 'admin' ||
        userRol == 'SuperAdmin';
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

/// Provider del repositorio de evaluaciones.
final evaluationRepositoryProvider = Provider<EvaluationRepository>((ref) {
  return EvaluationRepository(
    apiService: ref.watch(apiServiceProvider),
  );
});
