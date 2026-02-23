import 'package:equatable/equatable.dart';

/// ReadModel de comentario — para mostrar la lista de comentarios de un proyecto.
///
/// CQRS Query: solo lectura, optimizado para la UI.
/// Separado del modelo de escritura ([PostCommentCommand]).
class CommentReadModel extends Equatable {
  const CommentReadModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.userAvatarUrl,
    this.isOwn = false,
  });

  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final String? userAvatarUrl;

  /// True si el comentario pertenece al usuario autenticado actual.
  /// Permite alineación diferente y opción de eliminar.
  final bool isOwn;

  // ── Computed ────────────────────────────────────────────────────────

  /// Fecha relativa legible por humanos.
  String get fechaDisplay {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Iniciales del usuario para el avatar fallback.
  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, text, createdAt, isOwn];

  /// Factory desde fila de Supabase (snake_case).
  factory CommentReadModel.fromSupabaseRow(
    Map<String, dynamic> row, {
    required String? currentUserId,
  }) {
    return CommentReadModel(
      id: row['id'] as String? ?? '',
      projectId: row['project_id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      userName: row['user_name'] as String? ?? 'Anónimo',
      text: row['text'] as String? ?? '',
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      userAvatarUrl: row['user_avatar_url'] as String?,
      isOwn: currentUserId != null && row['user_id'] == currentUserId,
    );
  }
}

// ── CommandModel: Publicar comentario (CQRS Command) ──────────────────────

/// CommandModel para publicar un nuevo comentario en un proyecto.
///
/// Endpoint futuro: POST /api/comments
class PostCommentCommand {
  const PostCommentCommand({
    required this.projectId,
    required this.userId,
    required this.userName,
    required this.text,
    this.userAvatarUrl,
  });

  final String projectId;
  final String userId;
  final String userName;
  final String text;
  final String? userAvatarUrl;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'userId': userId,
        'text': text,
      };
}
