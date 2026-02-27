import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/config/api_endpoints.dart';
import 'package:biofrost/core/services/api_service.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/showcase/domain/models/project_read_model.dart';
import 'package:biofrost/features/project_detail/domain/models/project_detail_read_model.dart';

/// Datasource remoto para proyectos — solo lectura (CQRS Query).
///
/// Abstrae todas las llamadas al backend .NET relacionadas con proyectos.
/// Es invocado exclusivamente por [ProjectRepository].
class ProjectsRemoteDatasource {
  const ProjectsRemoteDatasource({required ApiService apiService})
      : _api = apiService;

  final ApiService _api;

  // ── GET /api/projects/public ───────────────────────────────────────

  /// Carga todos los proyectos públicos sin autenticación.
  Future<List<ProjectReadModel>> fetchPublicProjects() async {
    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.projectsPublic,
      authenticated: false,
    );
    return _parseList(response.data ?? []);
  }

  // ── GET /api/projects/group/{grupoId} ──────────────────────────────

  /// Carga los proyectos del grupo académico de un Docente.
  Future<List<ProjectReadModel>> fetchProjectsByGroup(String grupoId) async {
    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.projectsByGroup(grupoId),
    );
    return _parseList(response.data ?? []);
  }

  // ── GET /api/projects/teacher/{teacherId} ─────────────────────────

  /// Carga los proyectos supervisados por un Docente.
  Future<List<ProjectReadModel>> fetchProjectsByTeacher(
      String teacherId) async {
    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.projectsByTeacher(teacherId),
    );
    return _parseList(response.data ?? []);
  }

  // ── GET /api/projects/{id} ─────────────────────────────────────────

  /// Carga el detalle completo de un proyecto (miembros + canvas).
  Future<ProjectDetailReadModel> fetchProjectById(String projectId) async {
    final response = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.projectById(projectId),
      authenticated: false,
    );
    return ProjectDetailReadModel.fromJson(response.data!);
  }

  // ── POST /api/projects/{id}/rate ───────────────────────────────────

  /// Envía la calificación por estrellas del usuario.
  Future<void> rateProject({
    required String projectId,
    required String userId,
    required int stars,
  }) async {
    await _api.post<void>(
      ApiEndpoints.rateProject(projectId),
      data: {'userId': userId, 'stars': stars},
    );
  }

  // ── PATCH /api/projects/{id}/video-url ────────────────────────────

  /// Actualiza solo la URL del video pitch del proyecto.
  Future<void> updateVideoUrl(String projectId, String? videoUrl) async {
    await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.updateProjectVideoUrl(projectId),
      data: {'videoUrl': videoUrl},
      authenticated: true,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  List<ProjectReadModel> _parseList(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ProjectReadModel.fromJson)
        .toList();
  }
}

/// Provider del datasource remoto.
final projectsRemoteDatasourceProvider =
    Provider<ProjectsRemoteDatasource>((ref) {
  return ProjectsRemoteDatasource(
    apiService: ref.watch(apiServiceProvider),
  );
});
