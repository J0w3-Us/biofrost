import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/config/app_config.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/features/project_detail/domain/models/project_detail_read_model.dart';
import 'package:biofrost/features/showcase/data/datasources/projects_local_datasource.dart';
import 'package:biofrost/features/showcase/data/datasources/projects_remote_datasource.dart';
import 'package:biofrost/features/showcase/domain/models/project_read_model.dart';

/// Repositorio de proyectos — CQRS Query only (solo lectura).
///
/// Implementa el patrón Stale-While-Revalidate (AI/rules.md §5):
/// - Sirve desde caché local mientras refresca en background.
/// - TTL configurable por tipo de consulta.
///
/// Capas de caché: memoria → disco → red.
class ProjectRepository {
  ProjectRepository({
    required ProjectsRemoteDatasource remote,
    required ProjectsLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  final ProjectsRemoteDatasource _remote;
  final ProjectsLocalDatasource _local;

  // ── Caché en memoria ───────────────────────────────────────────────
  final Map<String, _CacheEntry<List<ProjectReadModel>>> _listCache = {};
  final Map<String, _CacheEntry<ProjectDetailReadModel>> _detailCache = {};

  // ── CQRS Query: Proyectos Públicos (Showcase + Ranking) ───────────

  /// GET /api/projects/public — sin autenticación requerida.
  Future<List<ProjectReadModel>> getPublicProjects({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'public';
    final memCached = _listCache[cacheKey];

    // 1. Caché en memoria
    if (!forceRefresh && memCached != null && !memCached.isExpired) {
      return memCached.data;
    }

    // 2. Caché en disco
    if (!forceRefresh) {
      final diskData = _local.readPublicProjects(
        ttl: AppConfig.showcaseCacheTtl,
      );
      if (diskData != null) {
        _listCache[cacheKey] =
            _CacheEntry(diskData, ttl: AppConfig.showcaseCacheTtl);
        return diskData;
      }
    }

    // 3. Red
    try {
      final projects = await _remote.fetchPublicProjects();
      _listCache[cacheKey] =
          _CacheEntry(projects, ttl: AppConfig.showcaseCacheTtl);
      await _local.writePublicProjects(projects);
      return projects;
    } on NetworkException {
      // Fallback offline: datos guardados aunque el TTL haya expirado
      final stale = _local.readPublicProjectsStale();
      if (stale != null) {
        _listCache[cacheKey] =
            _CacheEntry(stale, ttl: AppConfig.showcaseCacheTtl);
        return stale;
      }
      rethrow;
    }
  }

  /// Proyectos ordenados por puntuación para el Ranking.
  Future<List<ProjectReadModel>> getRanking({bool forceRefresh = false}) async {
    final projects = await getPublicProjects(forceRefresh: forceRefresh);
    return (List<ProjectReadModel>.from(projects)
          ..sort(
            (a, b) => (b.puntosTotales ?? 0).compareTo(a.puntosTotales ?? 0),
          ))
        .take(20)
        .toList();
  }

  // ── CQRS Query: Proyectos del Grupo (Docente) ──────────────────────

  /// GET /api/projects/group/{grupoId}
  Future<List<ProjectReadModel>> getProjectsByGroup(
    String grupoId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'group_$grupoId';
    final cached = _listCache[cacheKey];
    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final projects = await _remote.fetchProjectsByGroup(grupoId);
    _listCache[cacheKey] =
        _CacheEntry(projects, ttl: const Duration(minutes: 2));
    return projects;
  }

  // ── CQRS Query: Proyectos del Docente ─────────────────────────────

  /// GET /api/projects/teacher/{teacherId}
  Future<List<ProjectReadModel>> getProjectsByTeacher(
    String teacherId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'teacher_$teacherId';
    final cached = _listCache[cacheKey];
    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final projects = await _remote.fetchProjectsByTeacher(teacherId);
    _listCache[cacheKey] =
        _CacheEntry(projects, ttl: const Duration(minutes: 3));
    return projects;
  }

  // ── CQRS Query: Detalle de Proyecto ───────────────────────────────

  /// GET /api/projects/{id} — 3 capas: memoria → disco → red
  Future<ProjectDetailReadModel> getProjectById(
    String projectId, {
    bool forceRefresh = false,
  }) async {
    final memCached = _detailCache[projectId];

    // 1. Memoria
    if (!forceRefresh && memCached != null && !memCached.isExpired) {
      return memCached.data;
    }

    // 2. Disco
    if (!forceRefresh) {
      final diskData = _local.readProjectDetail(projectId);
      if (diskData != null) {
        _detailCache[projectId] = _CacheEntry(diskData);
        return diskData;
      }
    }

    // 3. Red
    try {
      final project = await _remote.fetchProjectById(projectId);
      _detailCache[projectId] = _CacheEntry(project);
      await _local.writeProjectDetail(project);
      return project;
    } on NetworkException {
      final stale = _local.readProjectDetailStale(projectId);
      if (stale != null) {
        _detailCache[projectId] = _CacheEntry(stale);
        return stale;
      }
      rethrow;
    }
  }

  // ── CQRS Command: Votar con estrellas ─────────────────────────────

  /// POST /api/projects/{id}/rate
  Future<void> rateProject({
    required String projectId,
    required String userId,
    required int stars,
  }) async {
    await _remote.rateProject(
      projectId: projectId,
      userId: userId,
      stars: stars,
    );
    invalidateProject(projectId);
  }

  // ── CQRS Command: Actualizar URL de video ─────────────────────────

  /// PATCH /api/projects/{id}/video-url
  Future<void> updateVideoUrl(String projectId, String? videoUrl) async {
    await _remote.updateVideoUrl(projectId, videoUrl);
    invalidateProject(projectId);
  }

  // ── Filtrado local ─────────────────────────────────────────────────

  List<ProjectReadModel> filterProjects(
    List<ProjectReadModel> projects, {
    String? searchTerm,
    String? selectedStack,
  }) {
    var result = projects;

    if (searchTerm != null && searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      result = result
          .where((p) =>
              p.titulo.toLowerCase().contains(term) ||
              p.materia.toLowerCase().contains(term) ||
              (p.liderNombre?.toLowerCase().contains(term) ?? false))
          .toList();
    }

    if (selectedStack != null && selectedStack.isNotEmpty) {
      result = result
          .where((p) => p.stackTecnologico.contains(selectedStack))
          .toList();
    }

    return result;
  }

  List<String> extractUniqueStacks(List<ProjectReadModel> projects) {
    final stacks = <String>{};
    for (final p in projects) {
      stacks.addAll(p.stackTecnologico);
    }
    return stacks.toList()..sort();
  }

  // ── Cache invalidation ─────────────────────────────────────────────

  void invalidateAll() {
    _listCache.clear();
    _detailCache.clear();
    _local.invalidateAll();
  }

  void invalidateProject(String projectId) {
    _detailCache.remove(projectId);
    _local.invalidateProjectDetail(projectId);
  }
}

// ── Entrada de caché con TTL ───────────────────────────────────────────

class _CacheEntry<T> {
  _CacheEntry(this.data, {Duration ttl = const Duration(minutes: 5)})
      : _expiry = DateTime.now().add(ttl);

  final T data;
  final DateTime _expiry;

  bool get isExpired => DateTime.now().isAfter(_expiry);
}

/// Provider del repositorio de proyectos.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(
    remote: ref.watch(projectsRemoteDatasourceProvider),
    local: ref.watch(projectsLocalDatasourceProvider),
  );
});
