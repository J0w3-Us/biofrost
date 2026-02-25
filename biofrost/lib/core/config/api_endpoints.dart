/// Endpoints del backend IntegradorHub (.NET).
///
/// Refleja el contrato de la API documentado en:
/// - IntegradorHub/docs/frontend/02_AUTH.md
/// - IntegradorHub/docs/frontend/04_PROJECTS.md
/// - IntegradorHub/docs/frontend/05_EVALUATIONS.md
library api_endpoints;

class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ───────────────────────────────────────────────────────────
  static const String login = '/auth/login';

  /// POST /api/auth/register — Registra un nuevo Docente con Firebase UID + perfil.
  static const String register = '/auth/register';

  /// GET /api/users/{uid}
  static String userById(String uid) => '/users/$uid';

  // ── Projects (Read - CQRS Query) ───────────────────────────────────

  /// GET /api/projects/public — Proyectos públicos (sin auth)
  static const String projectsPublic = '/projects/public';

  /// GET /api/projects/my-project?userId={uid}
  static String myProject(String userId) =>
      '/projects/my-project?userId=$userId';

  /// GET /api/projects/group/{grupoId} — Proyectos del grupo del docente
  static String projectsByGroup(String grupoId) => '/projects/group/$grupoId';

  /// GET /api/projects/teacher/{teacherId} — Proyectos supervisados por el docente
  static String projectsByTeacher(String teacherId) =>
      '/projects/teacher/$teacherId';

  /// GET /api/projects/{id}
  static String projectById(String id) => '/projects/$id';

  /// GET /api/projects/{id}/media
  static String projectMedia(String id) => '/projects/$id/media';

  // ── Evaluations ────────────────────────────────────────────────────

  /// GET /api/evaluations/project/{projectId}
  static String evaluationsByProject(String projectId) =>
      '/evaluations/project/$projectId';

  /// POST /api/evaluations
  static const String createEvaluation = '/evaluations';

  /// PATCH /api/evaluations/{id}/visibility
  static String evaluationVisibility(String id) =>
      '/evaluations/$id/visibility';

  // ── Teams ──────────────────────────────────────────────────────────

  /// GET /api/teams/available-students?groupId={gid}
  ///
  /// NOTA: El backend expone `available-students`, no `students`.
  static String teamStudents(String groupId) =>
      '/teams/available-students?groupId=$groupId';

  // ── Ratings (Vote) ─────────────────────────────────────────────────

  /// POST /api/projects/{id}/rate
  /// Body: { userId, stars }
  /// Implementa el sistema de votación con mapa Votantes del backend.
  static String rateProject(String projectId) => '/projects/$projectId/rate';

  // ── Users / Profile ────────────────────────────────────────────────

  /// PUT /api/users/{uid}/photo
  /// Body: { photoUrl }
  /// Persiste el campo FotoUrl en Firestore.
  static String updateUserPhoto(String uid) => '/users/$uid/photo';

  // ── Comments (Supabase) ───────────────────────────────────────────
  // Los comentarios de comunidad se almacenan en Supabase (tabla comments).
  // No pasan por el backend .NET.

  // ── Admin ──────────────────────────────────────────────────────────

  /// GET /api/admin/groups
  static const String adminGroups = '/admin/groups';

  /// GET /api/admin/materias/available?carreraId={id}
  static String availableMaterias(String carreraId) =>
      '/admin/materias/available?carreraId=$carreraId';

  /// GET /api/admin/carreras
  static const String adminCarreras = '/admin/carreras';

  // ── Projects (Write - CQRS Command) ───────────────────────────────

  /// PATCH /api/projects/{id}/video-url — Actualiza solo la URL de video.
  static String updateProjectVideoUrl(String id) => '/projects/$id/video-url';
}
