import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/comment_read_model.dart';

/// Servicio de acceso a Supabase.
///
/// Responsabilidades:
/// - Leer comentarios de la tabla `comments`.
/// - Insertar nuevos comentarios.
/// - Construir URLs públicas de Supabase Storage.
///
/// Instanciado como singleton vía [supabaseServiceProvider].
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Storage ─────────────────────────────────────────────────────────

  /// Devuelve la URL pública de un archivo en `project-files`.
  /// [filePath]: ruta relativa al bucket, ej.: "projects/abc/img.jpg"
  String publicUrl(String filePath) => AppConfig.storageUrl(filePath);

  // ── Comments ─────────────────────────────────────────────────────────

  /// Obtiene los comentarios de un proyecto ordenados del más reciente al más antiguo.
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

  /// Obtiene comentarios indicando el [currentUserId] para marcar `isOwn`.
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

  /// Inserta un comentario y devuelve el registro creado.
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

    return CommentReadModel.fromSupabaseRow(
      response,
      currentUserId: userId,
    );
  }
}

/// Provider singleton del [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((_) {
  return SupabaseService();
});
