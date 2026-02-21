import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biofrost/core/cache/cache_service.dart';

/// Registro ligero de analíticas de uso — 100% local, sin telemetría externa.
///
/// Persiste contadores en [SharedPreferences] para:
/// - **Visitas por proyecto** → identifica los proyectos más populares.
/// - **Clics en filtros de stack** → genera un heatmap de tecnologías buscadas.
///
/// No envía datos a ningún servidor externo. Los datos son estrictamente
/// de uso personal del usuario actual del dispositivo.
///
/// ### Uso
/// ```dart
/// final analytics = ref.read(analyticsServiceProvider);
/// await analytics.trackProjectVisit(project.id);
/// await analytics.trackStackFilter('Flutter');
///
/// final top = analytics.getTopProjects(); // → [MapEntry(id, count), ...]
/// final heat = analytics.getStackHeatmap(); // → [MapEntry('Flutter', 5), ...]
/// ```
class AnalyticsService {
  AnalyticsService(this._prefs);

  final SharedPreferences _prefs;

  static const _visitPrefix = 'analytics_visit_';
  static const _stackPrefix = 'analytics_stack_';

  // ── Track ──────────────────────────────────────────────────────────────────

  /// Registra una visita al proyecto [projectId].
  /// Incrementa el contador cada vez que se abre la pantalla de detalle.
  Future<void> trackProjectVisit(String projectId) async {
    final key = '$_visitPrefix$projectId';
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
  }

  /// Registra un clic en el filtro de stack [stackName] en el Showcase.
  Future<void> trackStackFilter(String stackName) async {
    final key = '$_stackPrefix$stackName';
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
  }

  /// Registra el envío de una evaluación: tipo 'sugerencia' u 'oficial'.
  ///
  /// Permite saber con qué frecuencia los docentes evalúan y qué tipo emiten.
  Future<void> trackEvaluationSubmit(String tipo) async {
    const prefix = 'analytics_eval_';
    final key = '$prefix$tipo';
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
  }

  /// Número de evaluaciones enviadas por tipo ('sugerencia' | 'oficial').
  int getEvaluationCount(String tipo) =>
      _prefs.getInt('analytics_eval_$tipo') ?? 0;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Top proyectos más visitados, ordenados por mayor número de visitas.
  ///
  /// Retorna hasta [limit] entradas `(projectId, visitCount)`.
  List<MapEntry<String, int>> getTopProjects({int limit = 10}) {
    final entries = _prefs
        .getKeys()
        .where((k) => k.startsWith(_visitPrefix))
        .map(
          (k) => MapEntry(
            k.substring(_visitPrefix.length),
            _prefs.getInt(k) ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).toList();
  }

  /// Heatmap de stacks tecnológicos más buscados, ordenados por conteo.
  ///
  /// Retorna hasta [limit] entradas `(stackName, clickCount)`.
  List<MapEntry<String, int>> getStackHeatmap({int limit = 20}) {
    final entries = _prefs
        .getKeys()
        .where((k) => k.startsWith(_stackPrefix))
        .map(
          (k) => MapEntry(
            k.substring(_stackPrefix.length),
            _prefs.getInt(k) ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).toList();
  }

  /// Número total de visitas de un proyecto específico.
  int getProjectVisitCount(String projectId) =>
      _prefs.getInt('$_visitPrefix$projectId') ?? 0;

  // ── Reset ──────────────────────────────────────────────────────────────────

  /// Elimina todas las analíticas acumuladas del dispositivo.
  Future<void> clearAll() async {
    final keys = _prefs
        .getKeys()
        .where(
          (k) => k.startsWith(_visitPrefix) || k.startsWith(_stackPrefix),
        )
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider del [AnalyticsService].
/// Reutiliza el [SharedPreferences] inyectado en el [ProviderScope].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AnalyticsService(prefs);
});
