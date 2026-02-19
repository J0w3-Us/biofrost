import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../data/models/public_project_read_model.dart';
import '../data/repositories/showcase_repository.dart';

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

enum ShowcaseStatus { idle, loading, success, error }

class ShowcaseState {
  const ShowcaseState({
    this.status = ShowcaseStatus.idle,
    this.projects = const [],
    this.filteredProjects = const [],
    this.allStacks = const [],
    this.searchTerm = '',
    this.selectedStack,
    this.errorMessage,
  });

  final ShowcaseStatus status;
  final List<PublicProjectReadModel> projects;
  final List<PublicProjectReadModel> filteredProjects;
  final List<String> allStacks;
  final String searchTerm;
  final String? selectedStack;
  final String? errorMessage;

  bool get isLoading => status == ShowcaseStatus.loading;
  bool get hasError => status == ShowcaseStatus.error;
  bool get isEmpty =>
      status == ShowcaseStatus.success && filteredProjects.isEmpty;

  ShowcaseState copyWith({
    ShowcaseStatus? status,
    List<PublicProjectReadModel>? projects,
    List<PublicProjectReadModel>? filteredProjects,
    List<String>? allStacks,
    String? searchTerm,
    Object? selectedStack = _sentinel,
    String? errorMessage,
  }) {
    return ShowcaseState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      filteredProjects: filteredProjects ?? this.filteredProjects,
      allStacks: allStacks ?? this.allStacks,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedStack: identical(selectedStack, _sentinel)
          ? this.selectedStack
          : selectedStack as String?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static const _sentinel = Object();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ShowcaseNotifier extends StateNotifier<ShowcaseState> {
  ShowcaseNotifier(this._repo) : super(const ShowcaseState()) {
    _load();
  }

  final IShowcaseRepository _repo;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> refresh() => _load();

  void search(String term) {
    final next = state.copyWith(searchTerm: term);
    state = next.copyWith(
      filteredProjects: _applyFilters(term: term, stack: next.selectedStack),
    );
  }

  void filterByStack(String? stack) {
    state = state.copyWith(
      selectedStack: stack,
      filteredProjects: _applyFilters(term: state.searchTerm, stack: stack),
    );
  }

  void clearFilters() {
    state = state.copyWith(
      searchTerm: '',
      selectedStack: null,
      filteredProjects: List.of(state.projects),
    );
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    state = state.copyWith(status: ShowcaseStatus.loading, errorMessage: null);
    try {
      final projects = await _repo.getPublicProjects();

      // Extraer stacks únicos ordenados
      final stacks = <String>{};
      for (final p in projects) {
        stacks.addAll(p.stackTecnologico);
      }
      final sortedStacks = stacks.toList()..sort();

      state = state.copyWith(
        status: ShowcaseStatus.success,
        projects: projects,
        filteredProjects: projects,
        allStacks: sortedStacks,
        searchTerm: '',
        selectedStack: null,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: ShowcaseStatus.error,
        errorMessage: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: ShowcaseStatus.error,
        errorMessage: 'No se pudo cargar la galería. Intenta de nuevo.',
      );
    }
  }

  List<PublicProjectReadModel> _applyFilters({
    required String term,
    required String? stack,
  }) {
    var result = List<PublicProjectReadModel>.from(state.projects);

    if (term.isNotEmpty) {
      final lower = term.toLowerCase();
      result = result.where((p) {
        return p.titulo.toLowerCase().contains(lower) ||
            p.materia.toLowerCase().contains(lower) ||
            p.liderNombre.toLowerCase().contains(lower);
      }).toList();
    }

    if (stack != null && stack.isNotEmpty) {
      result = result.where((p) {
        return p.stackTecnologico.any(
          (s) => s.toLowerCase() == stack.toLowerCase(),
        );
      }).toList();
    }

    return result;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final showcaseProvider = StateNotifierProvider<ShowcaseNotifier, ShowcaseState>(
  (ref) {
    return ShowcaseNotifier(ref.read(showcaseRepositoryProvider));
  },
);
