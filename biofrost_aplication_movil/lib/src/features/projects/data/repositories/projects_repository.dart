import '../../../../core/core.dart';
import '../models/add_member_command.dart';
import '../models/create_project_command.dart';
import '../models/project_detail_model.dart';
import '../models/project_list_item_model.dart';
import '../models/update_project_command.dart';
import '../../../showcase/data/models/canvas_block_model.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract class IProjectsRepository {
  Future<List<ProjectListItemModel>> getPublicProjects();
  Future<List<ProjectListItemModel>> getByGroup(String groupId);
  Future<ProjectDetailModel> getById(String id);
  Future<ProjectDetailModel?> getMyProject(String userId);
  Future<String> create(CreateProjectCommand command);
  Future<void> update(String id, UpdateProjectCommand command);
  Future<void> updateCanvas(
    String id,
    List<CanvasBlockModel> blocks,
    String userId,
  );
  Future<void> addMember(String id, AddMemberCommand command);
  Future<void> removeMember(
    String id,
    String memberId,
    String requestingUserId,
  );
  Future<void> delete(String id, String requestingUserId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ProjectsRepository implements IProjectsRepository {
  const ProjectsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ProjectListItemModel>> getPublicProjects() async {
    final data = await _client.get('/api/projects/public');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProjectListItemModel.fromPublicJson)
          .toList();
    }
    return [];
  }

  @override
  Future<List<ProjectListItemModel>> getByGroup(String groupId) async {
    final data = await _client.get('/api/projects/group/$groupId');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProjectListItemModel.fromGroupJson)
          .toList();
    }
    return [];
  }

  @override
  Future<ProjectDetailModel> getById(String id) async {
    final data = await _client.get('/api/projects/$id');
    return ProjectDetailModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ProjectDetailModel?> getMyProject(String userId) async {
    try {
      final data = await _client.get('/api/projects/my-project?userId=$userId');
      if (data == null) return null;
      return ProjectDetailModel.fromJson(data as Map<String, dynamic>);
    } on Object {
      // 404 → sin proyecto asignado
      return null;
    }
  }

  @override
  Future<String> create(CreateProjectCommand command) async {
    final data = await _client.post('/api/projects', body: command.toJson());
    final map = data as Map<String, dynamic>;
    return map['projectId'] as String? ?? map['id'] as String? ?? '';
  }

  @override
  Future<void> update(String id, UpdateProjectCommand command) async {
    await _client.put('/api/projects/$id', body: command.toJson());
  }

  @override
  Future<void> updateCanvas(
    String id,
    List<CanvasBlockModel> blocks,
    String userId,
  ) async {
    await _client.put(
      '/api/projects/$id/canvas',
      body: {
        'blocks': blocks
            .map(
              (b) => {
                'id': b.id,
                'type': b.type,
                'content': b.content,
                'order': b.order,
                if (b.metadata != null) 'metadata': b.metadata,
              },
            )
            .toList(),
        'userId': userId,
      },
    );
  }

  @override
  Future<void> addMember(String id, AddMemberCommand command) async {
    await _client.post('/api/projects/$id/members', body: command.toJson());
  }

  @override
  Future<void> removeMember(
    String id,
    String memberId,
    String requestingUserId,
  ) async {
    await _client.delete(
      '/api/projects/$id/members/$memberId?requestingUserId=$requestingUserId',
    );
  }

  @override
  Future<void> delete(String id, String requestingUserId) async {
    await _client.delete(
      '/api/projects/$id?requestingUserId=$requestingUserId',
    );
  }
}

// Provider is defined in cached_projects_repository.dart to avoid duplication.
