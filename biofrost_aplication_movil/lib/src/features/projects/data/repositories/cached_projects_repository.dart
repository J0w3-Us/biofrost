import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../models/add_member_command.dart';
import '../models/create_project_command.dart';
import '../models/project_detail_model.dart';
import '../models/project_list_item_model.dart';
import '../models/update_project_command.dart';
import '../../../showcase/data/models/canvas_block_model.dart';
import 'projects_repository.dart';

// ---------------------------------------------------------------------------
// Cache-key helpers
// ---------------------------------------------------------------------------

String _detailKey(String id) => 'project_detail_$id';
String _groupKey(String groupId) => 'project_group_$groupId';
String _myProjectKey(String userId) => 'project_my_$userId';
const _publicKey = 'projects_public';

// ---------------------------------------------------------------------------
// CachedProjectsRepository — Decorator over ProjectsRepository
// ---------------------------------------------------------------------------

/// Adds offline-first caching to [ProjectsRepository].
///
/// Strategy:
/// * **Network-first, cache fallback** — reads try the network; on failure
///   return the last cached value (stale-while-offline).
/// * **Optimistic canvas save** — if the device is offline, the operation is
///   stored in the [SyncQueueService] and retried automatically when the
///   device reconnects.
class CachedProjectsRepository implements IProjectsRepository {
  const CachedProjectsRepository({
    required this.inner,
    required this.cache,
    required this.connectivity,
    required this.syncQueue,
  });

  final IProjectsRepository inner;
  final CacheService cache;
  final ConnectivityService connectivity;
  final SyncQueueService syncQueue;

  // ── Reads — network-first, stale-on-offline ──────────────────────────────

  @override
  Future<List<ProjectListItemModel>> getPublicProjects() async {
    try {
      final items = await inner.getPublicProjects();
      await cache.putList(_publicKey, items.map((i) => i.toJson()).toList());
      return items;
    } on Object {
      final cached = await cache.getList(_publicKey);
      if (cached != null) {
        return cached.map(ProjectListItemModel.fromPublicJson).toList();
      }
      rethrow;
    }
  }

  @override
  Future<List<ProjectListItemModel>> getByGroup(String groupId) async {
    try {
      final items = await inner.getByGroup(groupId);
      await cache.putList(
        _groupKey(groupId),
        items.map((i) => i.toJson()).toList(),
      );
      return items;
    } on Object {
      final cached = await cache.getList(_groupKey(groupId));
      if (cached != null) {
        return cached.map(ProjectListItemModel.fromGroupJson).toList();
      }
      rethrow;
    }
  }

  @override
  Future<ProjectDetailModel> getById(String id) async {
    try {
      final model = await inner.getById(id);
      await cache.putMap(_detailKey(id), model.toJson());
      return model;
    } on Object {
      final cached = await cache.getMap(_detailKey(id));
      if (cached != null) return ProjectDetailModel.fromJson(cached);
      rethrow;
    }
  }

  @override
  Future<ProjectDetailModel?> getMyProject(String userId) async {
    try {
      final model = await inner.getMyProject(userId);
      if (model != null) {
        await cache.putMap(_myProjectKey(userId), model.toJson());
      }
      return model;
    } on Object {
      final cached = await cache.getMap(_myProjectKey(userId));
      if (cached != null) return ProjectDetailModel.fromJson(cached);
      return null;
    }
  }

  // ── Canvas save — enqueue when offline ────────────────────────────────────

  @override
  Future<void> updateCanvas(
    String id,
    List<CanvasBlockModel> blocks,
    String userId,
  ) async {
    final online = await connectivity.checkIsOnline();
    if (online) {
      await inner.updateCanvas(id, blocks, userId);
      // Invalidate cached detail so next read fetches fresh data.
      await cache.remove(_detailKey(id));
    } else {
      await syncQueue.enqueue(
        PendingOperation(
          id: '${id}_canvas_${DateTime.now().millisecondsSinceEpoch}',
          type: 'canvas_save',
          projectId: id,
          payload: {
            'blocks': blocks.map((b) => b.toJson()).toList(),
            'userId': userId,
          },
          createdAt: DateTime.now(),
        ),
      );
      // Update local cache optimistically.
      final cached = await cache.getMap(_detailKey(id));
      if (cached != null) {
        cached['canvas'] = blocks.map((b) => b.toJson()).toList();
        await cache.putMap(_detailKey(id), cached);
      }
    }
  }

  // ── Pass-through mutations ────────────────────────────────────────────────

  @override
  Future<String> create(CreateProjectCommand command) => inner.create(command);

  @override
  Future<void> update(String id, UpdateProjectCommand command) =>
      inner.update(id, command);

  @override
  Future<void> addMember(String id, AddMemberCommand command) =>
      inner.addMember(id, command);

  @override
  Future<void> removeMember(
    String id,
    String memberId,
    String requestingUserId,
  ) => inner.removeMember(id, memberId, requestingUserId);

  @override
  Future<void> delete(String id, String requestingUserId) =>
      inner.delete(id, requestingUserId);
}

// ---------------------------------------------------------------------------
// Provider — replaces the plain projectsRepositoryProvider
// ---------------------------------------------------------------------------

final projectsRepositoryProvider = Provider<IProjectsRepository>((ref) {
  return CachedProjectsRepository(
    inner: ProjectsRepository(ref.read(apiClientProvider)),
    cache: ref.read(cacheServiceProvider),
    connectivity: ref.read(connectivityServiceProvider),
    syncQueue: ref.read(syncQueueServiceProvider),
  );
});
