import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  const AppSettingsState({required this.themeMode});

  final ThemeMode themeMode;

  AppSettingsState copyWith({ThemeMode? themeMode}) {
    return AppSettingsState(themeMode: themeMode ?? this.themeMode);
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _themeModeKey = 'app_theme_mode';

  AppSettingsNotifier()
    : super(const AppSettingsState(themeMode: ThemeMode.light)) {
    _loadPersistedThemeMode();
  }

  Future<void> _loadPersistedThemeMode() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    final storedMode = prefs.getString(_themeModeKey);

    if (storedMode == ThemeMode.dark.name) {
      if (!mounted) return;
      state = state.copyWith(themeMode: ThemeMode.dark);
      return;
    }

    if (storedMode == ThemeMode.light.name) {
      if (!mounted) return;
      state = state.copyWith(themeMode: ThemeMode.light);
    }
  }

  Future<void> _persistThemeMode(ThemeMode themeMode) async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.setString(_themeModeKey, themeMode.name);
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // If plugin channels are not ready/missing, keep app running with in-memory state.
      return null;
    }
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
    _persistThemeMode(themeMode);
  }

  void setDarkModeEnabled(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((_) {
      return AppSettingsNotifier();
    });
