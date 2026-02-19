import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'connectivity_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// A mutation that could not be sent immediately because the device was offline.
class PendingOperation {
  final String id;

  /// Currently supported: `'canvas_save'`
  final String type;
  final String projectId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.projectId,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'projectId': projectId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'] as String,
        type: json['type'] as String,
        projectId: json['projectId'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Persists offline mutations to a dedicated Hive box and exposes a queue API.
class SyncQueueService {
  static const _boxName = 'bifrost_sync_queue';

  Future<Box<String>> _box() => Hive.openBox<String>(_boxName);

  Future<void> enqueue(PendingOperation op) async {
    final box = await _box();
    await box.put(op.id, jsonEncode(op.toJson()));
  }

  Future<void> dequeue(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<List<PendingOperation>> pendingOps() async {
    final box = await _box();
    return box.values
        .map(
          (raw) => PendingOperation.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<int> pendingCount() async => (await pendingOps()).length;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Watches connectivity and exposes the current pending-operation count.
///
/// Call [flush] with an async executor that sends each operation to the server.
class SyncQueueNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    // Re-read count whenever connectivity changes.
    ref.listen(isOnlineProvider, (_, next) async {
      final online = next.valueOrNull ?? false;
      if (online) {
        ref.invalidateSelf();
      }
    });
    return ref.read(syncQueueServiceProvider).pendingCount();
  }

  /// Process all pending operations with [send].
  /// [send] receives each [PendingOperation]; throw to abort and leave it queued.
  Future<void> flush(Future<void> Function(PendingOperation op) send) async {
    final service = ref.read(syncQueueServiceProvider);
    final ops = await service.pendingOps();
    for (final op in ops) {
      try {
        await send(op);
        await service.dequeue(op.id);
      } catch (_) {
        // Leave in queue for next retry.
      }
    }
    ref.invalidateSelf();
  }

  Future<void> enqueue(PendingOperation op) async {
    await ref.read(syncQueueServiceProvider).enqueue(op);
    ref.invalidateSelf();
  }
}

// ── Riverpod providers ────────────────────────────────────────────────────────

final syncQueueServiceProvider = Provider<SyncQueueService>(
  (_) => SyncQueueService(),
);

final syncQueueNotifierProvider = AsyncNotifierProvider<SyncQueueNotifier, int>(
  SyncQueueNotifier.new,
);
