import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:biofrost/core/errors/app_exceptions.dart';
import 'package:biofrost/core/models/comment_read_model.dart';
import 'package:biofrost/core/services/supabase_service.dart';
import 'package:biofrost/features/auth/providers/auth_provider.dart';

// ── Estado ─────────────────────────────────────────────────────────────────

/// Estado del hilo de comentarios de un proyecto.
class CommentsState {
  const CommentsState({
    this.comments = const [],
    this.draftText = '',
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submitError,
  });

  final List<CommentReadModel> comments;

  /// Texto en borrador del campo de texto.
  final String draftText;
  final bool isLoading;
  final bool isSubmitting;
  final AppException? error;
  final AppException? submitError;

  bool get hasError => error != null;
  bool get isEmpty => !isLoading && comments.isEmpty;

  /// El borrador tiene contenido suficiente para enviar (mínimo 3 chars).
  bool get canSubmit => draftText.trim().length >= 3 && !isSubmitting;

  CommentsState copyWith({
    List<CommentReadModel>? comments,
    String? draftText,
    bool? isLoading,
    bool? isSubmitting,
    AppException? error,
    bool clearError = false,
    AppException? submitError,
    bool clearSubmitError = false,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      draftText: draftText ?? this.draftText,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

/// Gestiona el hilo de comentarios de un proyecto.
///
/// CQRS:
/// - [_load] → Supabase tabla `comments` WHERE project_id = ? (Query)
/// - [postComment] → INSERT Supabase + Optimistic Update (Command)
class CommentsNotifier extends FamilyNotifier<CommentsState, String> {
  @override
  CommentsState build(String projectId) {
    Future.microtask(() => _load(projectId));
    return const CommentsState(isLoading: true);
  }

  SupabaseService get _supabase => ref.read(supabaseServiceProvider);

  // ── CQRS Query ──────────────────────────────────────────────────────

  /// Recarga los comentarios del proyecto (botón de reintentar).
  Future<void> reload(String projectId) => _load(projectId);

  /// Carga comentarios reales desde Supabase.
  Future<void> _load(String projectId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = ref.read(currentUserProvider);
      final comments = await _supabase.getCommentsForUser(
        projectId,
        currentUserId: user?.userId,
      );
      state = state.copyWith(isLoading: false, comments: comments);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AppException ? e : const NetworkException(),
      );
    }
  }

  // ── Form ────────────────────────────────────────────────────────────

  void setDraft(String text) =>
      state = state.copyWith(draftText: text, clearSubmitError: true);

  // ── CQRS Command: Publicar comentario ─────────────────────────────

  /// Publica un comentario con actualización optimista.
  ///
  /// 1. Inserta el comentario al inicio de la lista localmente.
  /// 2. Llama a Supabase para persistirlo.
  /// 3. Si falla: revierte y restaura el borrador.
  Future<bool> postComment(String projectId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw const AuthException();

    final text = state.draftText.trim();
    if (text.length < 3) return false;

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    final optimistic = CommentReadModel(
      id: 'opt-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      userId: user.userId,
      userName: user.nombreCompleto,
      text: text,
      createdAt: DateTime.now(),
      userAvatarUrl: user.fotoUrl,
      isOwn: true,
    );

    // 1. Optimistic prepend
    final previousComments = state.comments;
    state = state.copyWith(
      comments: [optimistic, ...state.comments],
      draftText: '',
    );

    // 2. Persistir en Supabase
    try {
      await _supabase.postComment(
        projectId: projectId,
        userId: user.userId,
        userName: user.nombreCompleto,
        text: text,
        userAvatarUrl: user.fotoUrl,
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } on AppException catch (e) {
      // 3. Rollback
      state = state.copyWith(
        comments: previousComments,
        draftText: text,
        isSubmitting: false,
        submitError: e,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        comments: previousComments,
        draftText: text,
        isSubmitting: false,
        submitError: const NetworkException(),
      );
      return false;
    }
  }
}

/// Provider parametrado por projectId.
final commentsProvider =
    NotifierProviderFamily<CommentsNotifier, CommentsState, String>(
  CommentsNotifier.new,
);
