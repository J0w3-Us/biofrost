import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:biofrost/core/config/app_config.dart';
import 'package:biofrost/features/project_detail/domain/models/comment_read_model.dart';

/// Datasource de comentarios — acceso a Supabase tabla `comments`.
///
/// Reemplaza el antiguo SupabaseService, ahora enfocado únicamente
/// en el dominio de comentarios de project_detail.
class CommentsDatasource {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Storage helper ─────────────────────────────────────────────────

  /// URL pública de un archivo en el bucket Supabase Storage.
  String publicUrl(String filePath) => AppConfig.storageUrl(filePath);

  // ── CQRS Query: Obtener comentarios ───────────────────────────────

  /// Carga comentarios de un proyecto ordenados del más reciente al más antiguo.
  Future<List<CommentReadModel>> getComments(String projectId) async {
    final response = await _client
        .from('comments')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return response
        .map((row) => CommentReadModel.fromSupabaseRow(
              row,
              currentUserId: null,
            ))
        .toList();
  }

  /// Carga comentarios marcando los propios del [currentUserId].
  Future<List<CommentReadModel>> getCommentsForUser(
    String projectId, {
    required String? currentUserId,
  }) async {
    final response = await _client
        .from('comments')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return response
        .map((row) => CommentReadModel.fromSupabaseRow(
              row,
              currentUserId: currentUserId,
            ))
        .toList();
  }

  // ── CQRS Command: Publicar comentario ─────────────────────────────

  /// INSERT en `comments` — retorna el registro creado.
  Future<CommentReadModel> postComment({
    required String projectId,
    required String userId,
    required String userName,
    required String text,
    String? userAvatarUrl,
  }) async {
    final response = await _client
        .from('comments')
        .insert({
          'project_id': projectId,
          'user_id': userId,
          'user_name': userName,
          'text': text,
          if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
        })
        .select()
        .single();

    return CommentReadModel.fromSupabaseRow(response, currentUserId: userId);
  }
}

/// Provider singleton del [CommentsDatasource].
final commentsDatasourceProvider = Provider<CommentsDatasource>((_) {
  return CommentsDatasource();
});
