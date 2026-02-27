import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/cache/cache_service.dart';
import 'package:biofrost/features/showcase/domain/models/project_read_model.dart';
import 'package:biofrost/features/project_detail/domain/models/project_detail_read_model.dart';

/// Datasource local para proyectos — caché en disco (SharedPreferences).
///
/// Implementa el patrón Stale-While-Revalidate:
/// - [read]: sirve datos si el TTL no ha expirado.
/// - [readStale]: sirve datos expirados para soporte offline.
/// - [write]: persiste datos con timestamp.
class ProjectsLocalDatasource {
  const ProjectsLocalDatasource({required CacheService cacheService})
      : _cache = cacheService;

  final CacheService _cache;

  // ── Proyectos públicos ─────────────────────────────────────────────

  List<ProjectReadModel>? readPublicProjects({
    Duration ttl = const Duration(minutes: 5),
  }) {
    final json = _cache.read(CacheService.keyProjects, ttl: ttl);
    if (json == null) return null;
    return _decodeList(json);
  }

  List<ProjectReadModel>? readPublicProjectsStale() {
    final json = _cache.readStale(CacheService.keyProjects);
    if (json == null) return null;
    return _decodeList(json);
  }

  Future<void> writePublicProjects(List<ProjectReadModel> projects) async {
    await _cache.write(
      CacheService.keyProjects,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }

  DateTime? publicProjectsSavedAt() =>
      _cache.getSavedAt(CacheService.keyProjects);

  // ── Detalle de proyecto ────────────────────────────────────────────

  ProjectDetailReadModel? readProjectDetail(String projectId) {
    final json = _cache.read('${CacheService.keyProjectPrefix}$projectId');
    if (json == null) return null;
    return ProjectDetailReadModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  }

  ProjectDetailReadModel? readProjectDetailStale(String projectId) {
    final json = _cache.readStale('${CacheService.keyProjectPrefix}$projectId');
    if (json == null) return null;
    return ProjectDetailReadModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> writeProjectDetail(ProjectDetailReadModel project) async {
    await _cache.write(
      '${CacheService.keyProjectPrefix}${project.id}',
      jsonEncode(project.toJson()),
    );
  }

  void invalidateProjectDetail(String projectId) {
    _cache.invalidate('${CacheService.keyProjectPrefix}$projectId');
  }

  void invalidateAll() => _cache.clearAll();

  // ── Helpers ────────────────────────────────────────────────────────

  List<ProjectReadModel> _decodeList(String json) {
    return (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(ProjectReadModel.fromJson)
        .toList();
  }
}

/// Provider del datasource local.
final projectsLocalDatasourceProvider =
    Provider<ProjectsLocalDatasource>((ref) {
  return ProjectsLocalDatasource(
    cacheService: ref.watch(cacheServiceProvider),
  );
});
