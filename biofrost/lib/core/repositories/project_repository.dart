import 'dart:convert';

import '../cache/cache_service.dart';
import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../errors/app_exceptions.dart';
import '../models/project_read_model.dart';
import '../services/api_service.dart';

/// Repositorio de proyectos — CQRS Query (solo lectura).
///
/// Implementa el patrón Stale-While-Revalidate (AI/rules.md §5):
/// - Sirve desde caché local mientras refresca en background.
/// - TTL configurable por tipo de consulta.
///
/// Todos los métodos son queries; no hay comandos de escritura en este repositorio.
class ProjectRepository {
  ProjectRepository({
    required ApiService apiService,
    required CacheService cacheService,
  })  : _api = apiService,
        _cache = cacheService;

  final ApiService _api;
  final CacheService _cache;

  // ── Caché en memoria (Stale-While-Revalidate) ──────────────────────
  final Map<String, _CacheEntry<List<ProjectReadModel>>> _listCache = {};
  final Map<String, _CacheEntry<ProjectDetailReadModel>> _detailCache = {};

  // ── Proyectos Públicos (Showcase + Ranking) ────────────────────────

  /// Obtiene todos los proyectos públicos.
  /// Sin autenticación requerida.
  ///
  /// Endpoint: GET /api/projects/public
  Future<List<ProjectReadModel>> getPublicProjects({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'public';
    final memCached = _listCache[cacheKey];

    // 1. Caché en memoria (más rápida)
    if (!forceRefresh && memCached != null && !memCached.isExpired) {
      return memCached.data;
    }

    // 2. Caché en disco (offline support)
    if (!forceRefresh) {
      final diskJson = _cache.read(
        CacheService.keyProjects,
        ttl: AppConfig.showcaseCacheTtl,
      );
      if (diskJson != null) {
        final projects = _parseProjectList(
          (jsonDecode(diskJson) as List).cast<Map<String, dynamic>>(),
        );
        _listCache[cacheKey] = _CacheEntry(projects, ttl: AppConfig.showcaseCacheTtl);
        return projects;
      }
    }

    // 3. Red
    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.projectsPublic,
      authenticated: false,
    );

    final projects = _parseProjectList(response.data ?? []);
    _listCache[cacheKey] = _CacheEntry(projects, ttl: AppConfig.showcaseCacheTtl);

    // Persistir en disco
    await _cache.write(
      CacheService.keyProjects,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );

    return projects;
  }

  /// Obtiene proyectos públicos ordenados por puntuación para el Ranking.
  ///
  /// Retorna máximo [AppConfig.rankingMaxVisible] proyectos.
  Future<List<ProjectReadModel>> getRanking({bool forceRefresh = false}) async {
    final projects = await getPublicProjects(forceRefresh: forceRefresh);
    final sorted = List<ProjectReadModel>.from(projects)
      ..sort(
        (a, b) => (b.puntosTotales ?? 0).compareTo(a.puntosTotales ?? 0),
      );
    return sorted.take(20).toList();
  }

  // ── Proyectos del Grupo (Docente) ──────────────────────────────────

  /// Obtiene todos los proyectos de un grupo académico.
  /// Requiere autenticación de Docente.
  ///
  /// Endpoint: GET /api/projects/group/{grupoId}
  Future<List<ProjectReadModel>> getProjectsByGroup(
    String grupoId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'group_$grupoId';
    final cached = _listCache[cacheKey];

    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final response = await _api.get<List<dynamic>>(
      ApiEndpoints.projectsByGroup(grupoId),
    );

    final projects = _parseProjectList(response.data ?? []);
    _listCache[cacheKey] = _CacheEntry(projects, ttl: const Duration(minutes: 2));
    return projects;
  }

  // ── Detalle de Proyecto ────────────────────────────────────────────

  /// Obtiene los detalles completos de un proyecto por ID.
  /// Incluye miembros del equipo, canvas y metadata.
  ///
  /// Endpoint: GET /api/projects/{id}
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
      final diskJson = _cache.read(
        '${CacheService.keyProjectPrefix}$projectId',
      );
      if (diskJson != null) {
        final project = ProjectDetailReadModel.fromJson(
          jsonDecode(diskJson) as Map<String, dynamic>,
        );
        _detailCache[projectId] = _CacheEntry(project);
        return project;
      }
    }

    // 3. Red
    final response = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.projectById(projectId),
    );

    if (response.data == null) {
      throw NotFoundException(
        message: 'El proyecto con ID $projectId no fue encontrado.',
      );
    }

    final project = ProjectDetailReadModel.fromJson(response.data!);
    _detailCache[projectId] = _CacheEntry(project);

    // Persistir en disco
    await _cache.write(
      '${CacheService.keyProjectPrefix}$projectId',
      jsonEncode(project.toJson()),
    );

    return project;
  }

  // ── Filtrado local (sin llamada adicional a API) ───────────────────

  /// Filtra una lista de proyectos por término de búsqueda y/o tecnología.
  /// Documentado en 06_PUBLIC_PAGES.md § Lógica de Filtrado.
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

  /// Extrae el set de tecnologías únicas de una lista de proyectos.
  /// Documentado en 06_PUBLIC_PAGES.md § Extracción de Stacks Únicos.
  List<String> extractUniqueStacks(List<ProjectReadModel> projects) {
    final stacks = <String>{};
    for (final p in projects) {
      stacks.addAll(p.stackTecnologico);
    }
    return stacks.toList()..sort();
  }

  // ── Cache invalidation ─────────────────────────────────────────────

  /// Invalida todos los cachés (útil tras operaciones de escritura).
  void invalidateAll() {
    _listCache.clear();
    _detailCache.clear();
    _cache.clearAll();
  }

  /// Invalida el caché de detalles de un proyecto específico.
  void invalidateProject(String projectId) {
    _detailCache.remove(projectId);
    _cache.invalidate('${CacheService.keyProjectPrefix}$projectId');
  }

  // ── Helpers ────────────────────────────────────────────────────────

  List<ProjectReadModel> _parseProjectList(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ProjectReadModel.fromJson)
        .toList();
  }
}

// ── Entrada de caché con TTL ────────────────────────────────────────────

class _CacheEntry<T> {
  _CacheEntry(this.data, {Duration ttl = const Duration(minutes: 5)})
      : _expiry = DateTime.now().add(ttl);

  final T data;
  final DateTime _expiry;

  bool get isExpired => DateTime.now().isAfter(_expiry);
}
