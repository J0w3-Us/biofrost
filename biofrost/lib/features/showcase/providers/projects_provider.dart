import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/cache/cache_service.dart';
import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/repositories/project_repository.dart';
import 'package:biofrost/core/services/analytics_service.dart';
import 'package:biofrost/core/services/connectivity_service.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';

// ── Provider base: Repositorio ──────────────────────────────────────────

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(
    apiService: ref.watch(apiServiceProvider),
    cacheService: ref.watch(cacheServiceProvider),
  );
});

// ── Estado del módulo Showcase ──────────────────────────────────────────

/// Estado reactivo de la galería de proyectos públicos.
class ShowcaseState {
  const ShowcaseState({
    this.allProjects = const [],
    this.filteredProjects = const [],
    this.allStacks = const [],
    this.searchTerm = '',
    this.selectedStack,
    this.isLoading = false,
    this.error,
    this.cachedAt,
  });

  final List<ProjectReadModel> allProjects;
  final List<ProjectReadModel> filteredProjects;

  /// Sets de tecnologías únicas para los filter chips.
  final List<String> allStacks;
  final String searchTerm;
  final String? selectedStack;
  final bool isLoading;
  final AppException? error;

  /// Marca de tiempo del último dato guardado en caché.
  /// Permite mostrar el badge "Actualizado hace X min".
  final DateTime? cachedAt;

  bool get hasError => error != null;
  bool get isEmpty => !isLoading && filteredProjects.isEmpty;

  ShowcaseState copyWith({
    List<ProjectReadModel>? allProjects,
    List<ProjectReadModel>? filteredProjects,
    List<String>? allStacks,
    String? searchTerm,
    String? selectedStack,
    bool clearSelectedStack = false,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    DateTime? cachedAt,
  }) {
    return ShowcaseState(
      allProjects: allProjects ?? this.allProjects,
      filteredProjects: filteredProjects ?? this.filteredProjects,
      allStacks: allStacks ?? this.allStacks,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedStack:
          clearSelectedStack ? null : (selectedStack ?? this.selectedStack),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

// ── Notifier de Showcase ────────────────────────────────────────────────

/// Gestiona la galería de proyectos públicos.
///
/// Patrón CQRS (lectura):
/// - [load] → GET /api/projects/public → almacena en caché
/// - [applySearch] / [applyStackFilter] → filtrado local sin API
///
/// ### Módulo 4 — Retry automático
/// Al recuperar la red, [RetryScheduler] reintenta [load] con backoff
/// exponencial (2 s → 4 s → 8 s, máx 3 intentos).
class ShowcaseNotifier extends Notifier<ShowcaseState> {
  late RetryScheduler _retryScheduler;

  @override
  ShowcaseState build() {
    _retryScheduler = RetryScheduler(
      action: () => load(forceRefresh: true),
    );
    _retryScheduler.startOnRestore();
    ref.onDispose(_retryScheduler.cancel);

    // Carga automática al inicializar el provider.
    Future.microtask(load);
    return const ShowcaseState(isLoading: true);
  }

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  // ── CQRS Query ───────────────────────────────────────────────────────

  /// Carga (o refresca) proyectos públicos desde la API.
  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final projects = await _repo.getPublicProjects(
        forceRefresh: forceRefresh,
      );
      final stacks = _repo.extractUniqueStacks(projects);
      final cachedAt =
          ref.read(cacheServiceProvider).getSavedAt(CacheService.keyProjects);

      state = state.copyWith(
        allProjects: projects,
        filteredProjects: projects,
        allStacks: stacks,
        isLoading: false,
        cachedAt: cachedAt,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ── Filtrado local ───────────────────────────────────────────────────

  /// Aplica filtro de búsqueda por texto.
  /// Filtering is purely local — no API call.
  void applySearch(String term) {
    state = state.copyWith(searchTerm: term);
    _filterAndUpdate();
  }

  /// Aplica filtro por tecnología del stack.
  /// Registra el clic en [AnalyticsService] para el heatmap de stacks.
  void applyStackFilter(String? stack) {
    state = state.copyWith(
      selectedStack: stack,
      clearSelectedStack: stack == null,
    );
    _filterAndUpdate();
    if (stack != null) {
      ref.read(analyticsServiceProvider).trackStackFilter(stack);
    }
  }

  /// Limpia todos los filtros.
  void clearFilters() {
    state = state.copyWith(
      searchTerm: '',
      clearSelectedStack: true,
      filteredProjects: state.allProjects,
    );
  }

  void _filterAndUpdate() {
    final filtered = _repo.filterProjects(
      state.allProjects,
      searchTerm: state.searchTerm,
      selectedStack: state.selectedStack,
    );
    state = state.copyWith(filteredProjects: filtered);
  }
}

/// Provider de la galería de proyectos públicos.
final showcaseProvider = NotifierProvider<ShowcaseNotifier, ShowcaseState>(
  ShowcaseNotifier.new,
);

// ── Ranking ─────────────────────────────────────────────────────────────

/// Estado del ranking de proyectos.
class RankingState {
  const RankingState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
    this.cachedAt,
  });

  final List<ProjectReadModel> projects;
  final bool isLoading;
  final AppException? error;

  /// Marca de tiempo del último dato guardado en caché.
  final DateTime? cachedAt;

  /// Top 3 para el podio.
  List<ProjectReadModel> get podium => projects.take(3).toList();

  /// Posiciones 4-20 para la tabla.
  List<ProjectReadModel> get table => projects.skip(3).toList();

  bool get hasError => error != null;

  RankingState copyWith({
    List<ProjectReadModel>? projects,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    DateTime? cachedAt,
  }) {
    return RankingState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

class RankingNotifier extends Notifier<RankingState> {
  late RetryScheduler _retryScheduler;

  @override
  RankingState build() {
    _retryScheduler = RetryScheduler(
      action: () => load(forceRefresh: true),
    );
    _retryScheduler.startOnRestore();
    ref.onDispose(_retryScheduler.cancel);

    Future.microtask(load);
    return const RankingState(isLoading: true);
  }

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ranked = await _repo.getRanking(forceRefresh: forceRefresh);
      final cachedAt =
          ref.read(cacheServiceProvider).getSavedAt(CacheService.keyRanking);
      state = state.copyWith(
        projects: ranked,
        isLoading: false,
        cachedAt: cachedAt,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final rankingProvider = NotifierProvider<RankingNotifier, RankingState>(
  RankingNotifier.new,
);

// ── Detalle de Proyecto ──────────────────────────────────────────────────

/// Provider de detalle de un proyecto específico.
/// Usa [FutureProvider.family] para parametrización por ID.
final projectDetailProvider = FutureProvider.autoDispose
    .family<ProjectDetailReadModel, String>((ref, projectId) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getProjectById(projectId);
});

// ── Proyectos del grupo del Docente ───────────────────────────────────────

/// Estado de la lista de proyectos del grupo para el Docente.
class DocenteProjectsState {
  const DocenteProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
    this.selectedProjectId,
  });

  final List<ProjectReadModel> projects;
  final bool isLoading;
  final AppException? error;
  final String? selectedProjectId;

  bool get hasError => error != null;

  DocenteProjectsState copyWith({
    List<ProjectReadModel>? projects,
    bool? isLoading,
    AppException? error,
    bool clearError = false,
    String? selectedProjectId,
    bool clearSelected = false,
  }) {
    return DocenteProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedProjectId:
          clearSelected ? null : (selectedProjectId ?? this.selectedProjectId),
    );
  }
}

class DocenteProjectsNotifier extends Notifier<DocenteProjectsState> {
  @override
  DocenteProjectsState build() {
    // Escucha cambios del usuario para obtener su grupoId
    final user = ref.watch(currentUserProvider);
    if (user?.isDocente == true && user?.grupoId != null) {
      Future.microtask(() => loadForGroup(user!.grupoId!));
    }
    return const DocenteProjectsState(isLoading: true);
  }

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  Future<void> loadForGroup(String grupoId, {bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final projects = await _repo.getProjectsByGroup(
        grupoId,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(projects: projects, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void selectProject(String? projectId) {
    state = state.copyWith(
      selectedProjectId: projectId,
      clearSelected: projectId == null,
    );
  }
}

final docenteProjectsProvider =
    NotifierProvider<DocenteProjectsNotifier, DocenteProjectsState>(
  DocenteProjectsNotifier.new,
);

// ── Proyectos vistos recientemente ──────────────────────────────────────────

/// IDs de los proyectos vistos recientemente (más reciente primero).
/// Se actualiza cada vez que el usuario entra al detalle de un proyecto.
final recentlyViewedIdsProvider = Provider<List<String>>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return cache.getRecentlyViewedIds();
});

/// Detalle (desde caché) de los proyectos visitados recientemente.
/// Filtra automáticamente IDs sin datos en caché (evita requests de red).
final recentlyViewedProjectsProvider =
    FutureProvider<List<ProjectDetailReadModel>>((ref) async {
  final ids = ref.watch(recentlyViewedIdsProvider);
  final repo = ref.watch(projectRepositoryProvider);

  final results = <ProjectDetailReadModel>[];
  for (final id in ids) {
    try {
      // Solo sirve desde caché disco; si no hay datos no lanza excepción
      // porque getProjectById ya revisa caché antes de ir a la red.
      final project = await repo.getProjectById(id);
      results.add(project);
    } catch (_) {
      // Ignorar si el proyecto no está en caché ni en red
    }
  }
  return results;
});
