import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/star_rating_read_model.dart';
import 'package:biofrost/core/repositories/project_repository.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';
import 'package:biofrost/features/showcase/providers/projects_provider.dart';

// ── Estado ─────────────────────────────────────────────────────────────────

/// Estado del rating por estrellas de un proyecto.
class StarRatingState {
  const StarRatingState({
    this.rating,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitError,
  });

  final StarRatingReadModel? rating;
  final bool isLoading;
  final bool isSubmitting;
  final AppException? error;
  final AppException? submitError;

  bool get hasError => error != null;
  bool get hasData => rating != null;

  StarRatingState copyWith({
    StarRatingReadModel? rating,
    bool? isLoading,
    bool? isSubmitting,
    AppException? error,
    bool clearError = false,
    AppException? submitError,
    bool clearSubmitError = false,
  }) {
    return StarRatingState(
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

/// Gestiona el estado de calificación por estrellas de un proyecto.
///
/// Fix aplicado de IntegradorHub/docs/Project_Rating_Fixes.md:
/// - Carga `userStars` desde el mapa `Votantes` del backend (ya no arranca en null siempre).
/// - Envío usa `user.userId` (no `user.id` — era el bug que causaba Error 400).
/// - Rollback automático si el backend rechaza el voto.
///
/// CQRS:
/// - Query  → [_loadFromProject]: GET /api/projects/{id} y extrae Votantes.
/// - Command → [submitRating]: POST /api/projects/{id}/rate + Optimistic Update.
class StarRatingNotifier extends FamilyNotifier<StarRatingState, String> {
  @override
  StarRatingState build(String projectId) {
    Future.microtask(() => _loadFromProject(projectId));
    return const StarRatingState(isLoading: true);
  }

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  // ── CQRS Query: Cargar desde proyecto ──────────────────────────────

  /// Obtiene el detalle del proyecto y extrae los datos de rating del
  /// mapa Votantes del backend.
  ///
  /// average = sum(votantes.values) / count(votantes)
  /// userStars = votantes[user.userId] si el usuario ya votó.
  Future<void> _loadFromProject(String projectId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final project = await _repo.getProjectById(projectId);
      final user = ref.read(currentUserProvider);

      final votantes = project.votantes ?? {};
      final total = project.conteoVotos ?? votantes.length;
      final sum = votantes.values.fold<int>(0, (a, b) => a + b);
      final avg = total > 0 ? sum / total : 0.0;
      final userStars = user != null ? votantes[user.userId] : null;

      state = state.copyWith(
        isLoading: false,
        rating: StarRatingReadModel(
          projectId: projectId,
          average: double.parse(avg.toStringAsFixed(1)),
          totalVotes: total,
          userStars: userStars,
        ),
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (_) {
      // Si falla la carga, mostrar rating vacío (no bloquear UI).
      state = state.copyWith(
        isLoading: false,
        rating: StarRatingReadModel(
          projectId: projectId,
          average: 0.0,
          totalVotes: 0,
        ),
      );
    }
  }

  /// Recarga el rating (pull-to-refresh).
  Future<void> reload() async => _loadFromProject(arg);

  // ── CQRS Command: Votar con estrellas ─────────────────────────────

  /// Registra la calificación del usuario con actualización optimista.
  ///
  /// 1. Calcula el nuevo promedio localmente (UI responde al instante).
  /// 2. Llama al backend real: POST /api/projects/{id}/rate.
  /// 3. Si falla: revierte al estado anterior + muestra error.
  Future<void> submitRating(int stars) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw const AuthException();
    if (stars < 1 || stars > 5) return;

    final prev = state.rating;
    if (prev == null) return;

    final isChangingVote = prev.hasVoted;
    final newTotal = isChangingVote ? prev.totalVotes : prev.totalVotes + 1;
    final newAverage = isChangingVote
        ? _recalcAverage(prev.average, prev.totalVotes, prev.userStars!, stars)
        : ((prev.average * prev.totalVotes) + stars) / newTotal;

    // 1. Optimistic update — la UI responde de inmediato
    state = state.copyWith(
      isSubmitting: true,
      rating: prev.copyWith(
        userStars: stars,
        average: double.parse(newAverage.toStringAsFixed(1)),
        totalVotes: newTotal,
      ),
    );

    try {
      // 2. Llamada real al backend (fix: user.userId, no user.id)
      await _repo.rateProject(
        projectId: prev.projectId,
        userId: user.userId,
        stars: stars,
      );
      state = state.copyWith(isSubmitting: false, clearSubmitError: true);
    } on AppException catch (e) {
      // 3. Rollback si el backend rechaza el voto
      state = state.copyWith(
        isSubmitting: false,
        rating: prev,
        submitError: e,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  double _recalcAverage(
    double currentAvg,
    int totalVotes,
    int oldStars,
    int newStars,
  ) {
    final sum = currentAvg * totalVotes - oldStars + newStars;
    return sum / totalVotes;
  }
}

/// Provider parametrado por projectId.
final starRatingProvider =
    NotifierProviderFamily<StarRatingNotifier, StarRatingState, String>(
  StarRatingNotifier.new,
);
