import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper around a Hive [Box<String>] that stores arbitrary JSON.
///
/// All data is serialised to JSON strings — no TypeAdapters needed.
/// Box is opened lazily on first use (Hive deduplicates open boxes).
class CacheService {
  static const _boxName = 'bifrost_cache';

  Future<Box<String>> _box() => Hive.openBox<String>(_boxName);

  // ── Map (single object) ────────────────────────────────────────────────────

  Future<void> putMap(String key, Map<String, dynamic> value) async {
    final box = await _box();
    await box.put(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getMap(String key) async {
    final box = await _box();
    final raw = box.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── List (collection of objects) ──────────────────────────────────────────

  Future<void> putList(String key, List<Map<String, dynamic>> items) async {
    final box = await _box();
    await box.put(key, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>?> getList(String key) async {
    final box = await _box();
    final raw = box.get(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  Future<void> remove(String key) async {
    final box = await _box();
    await box.delete(key);
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final cacheServiceProvider = Provider<CacheService>((_) => CacheService());
