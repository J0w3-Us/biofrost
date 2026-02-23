import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biofrost/core/config/app_config.dart';

/// Servicio de caché genérico con TTL configurable.
///
/// Persiste datos JSON en [SharedPreferences] junto con un timestamp
/// de expiración. Usa [AppConfig.cacheTimeout] como duración por defecto.
///
/// ### Uso
/// ```dart
/// final cache = ref.watch(cacheServiceProvider);
/// await cache.write('projects_all', proyectosJson);
/// final json = await cache.read('projects_all');
/// ```
class CacheService {
  CacheService(this._prefs);

  final SharedPreferences _prefs;

  // ── Claves públicas ───────────────────────────────────────────────────────
  static const String keyProjects = 'cache_projects_showcase';
  static const String keyRanking = 'cache_projects_ranking';
  static const String keyProjectPrefix = 'cache_project_'; // + id
  static const String keyEvalPrefix = 'cache_evals_'; // + projectId

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Devuelve el JSON almacenado si no ha expirado, o `null` si caducó.
  String? read(String key, {Duration? ttl}) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        wrapper['ts'] as int,
      );
      final expiry = ttl ?? AppConfig.cacheTimeout;

      if (DateTime.now().difference(savedAt) > expiry) {
        // No eliminamos los datos — pueden usarse como fallback offline.
        // Se sobreescriben cuando llegan datos frescos de la red.
        return null;
      }

      return wrapper['data'] as String;
    } catch (_) {
      _prefs.remove(key);
      return null;
    }
  }

  /// Devuelve el JSON almacenado **ignorando el TTL**.
  ///
  /// Usar exclusivamente como fallback offline cuando la red falla
  /// y el caché normal ya expiró. Nunca use esto para lógica normal.
  String? readStale(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      return wrapper['data'] as String;
    } catch (_) {
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Guarda [data] (JSON string) bajo [key] con timestamp actual.
  Future<void> write(String key, String data) async {
    final wrapper = jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    });
    await _prefs.setString(key, wrapper);
  }

  // ── Invalidation ──────────────────────────────────────────────────────────

  /// Elimina una entrada específica del caché.
  Future<void> invalidate(String key) => _prefs.remove(key).then((_) {});

  /// Elimina todas las entradas cuya clave empiece por [prefix].
  Future<void> invalidateByPrefix(String prefix) async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Limpia todo el caché de la app.
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // ── Proyectos vistos recientemente ─────────────────────────────────────────

  static const String keyRecentlyViewed = 'cache_recently_viewed';
  static const int maxRecentlyViewed = 10;

  /// Añade [projectId] al tope de la lista de proyectos vistos recientemente.
  /// Mantiene un máximo de [maxRecentlyViewed] entradas únicas.
  Future<void> addRecentlyViewed(String projectId) async {
    var ids = getRecentlyViewedIds();
    ids
      ..remove(projectId) // elimina duplicado si ya existe
      ..insert(0, projectId); // inserta al frente (más reciente)
    if (ids.length > maxRecentlyViewed) {
      ids = ids.take(maxRecentlyViewed).toList();
    }
    await _prefs.setString(keyRecentlyViewed, jsonEncode(ids));
  }

  /// Devuelve la lista de project-IDs visitados recientemente (más reciente primero).
  List<String> getRecentlyViewedIds() {
    final raw = _prefs.getString(keyRecentlyViewed);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  /// Limpia el historial de visitas recientes.
  Future<void> clearRecentlyViewed() =>
      _prefs.remove(keyRecentlyViewed).then((_) {});

  // ── Metadatos de caché ────────────────────────────────────────────────────

  /// Devuelve cuándo fue guardada la entrada con [key], **sin** verificar TTL.
  ///
  /// Útil para mostrar "Actualizado hace X min" en la UI aunque el caché
  /// siga siendo válido. Retorna `null` si la clave no existe.
  DateTime? getSavedAt(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.fromMillisecondsSinceEpoch(wrapper['ts'] as int);
    } catch (_) {
      return null;
    }
  }

  // ── Snapshot recientes ────────────────────────────────────────────────────

  /// Devuelve cuántas entradas de caché están activas.
  int get activeEntries =>
      _prefs.getKeys().where((k) => k.startsWith('cache_')).length;
}

// ── Providers ────────────────────────────────────────────────────────────────

/// Provider de [SharedPreferences] — se inicializa en main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider no fue sobreescrito en ProviderScope. '
    'Asegúrate de usar overrides en main().',
  );
});

/// Provider del [CacheService].
final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheService(prefs);
});
