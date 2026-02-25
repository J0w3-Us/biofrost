import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_service.dart';

/// Key in SharedPreferences
const _kAppThemeKey = 'app_theme_mode';

enum AppThemeModeOption { dark, light }

class ThemeNotifier extends Notifier<AppThemeModeOption> {
  @override
  AppThemeModeOption build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kAppThemeKey);
    if (stored == 'light') return AppThemeModeOption.light;
    return AppThemeModeOption.dark;
  }

  Future<void> setMode(AppThemeModeOption mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
        _kAppThemeKey, mode == AppThemeModeOption.light ? 'light' : 'dark');
  }

  Future<void> toggle() async {
    final next = state == AppThemeModeOption.dark
        ? AppThemeModeOption.light
        : AppThemeModeOption.dark;
    await setMode(next);
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, AppThemeModeOption>(ThemeNotifier.new);
