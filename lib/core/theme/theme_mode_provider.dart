import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appearance preferences — extensible for future accent/theme customization.
class AppSettingsState {
  const AppSettingsState({
    required this.themeMode,
    this.accentPreset = AppAccentPreset.trustBlue,
  });

  final ThemeMode themeMode;
  final AppAccentPreset accentPreset;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    AppAccentPreset? accentPreset,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentPreset: accentPreset ?? this.accentPreset,
    );
  }
}

/// Future-ready accent presets (stored but not yet applied to ColorScheme).
enum AppAccentPreset {
  trustBlue('trust_blue', 'أزرق الثقة'),
  safetyGreen('safety_green', 'أخضر الأمان'),
  alertRed('alert_red', 'أحمر التنبيه');

  const AppAccentPreset(this.storageKey, this.labelAr);
  final String storageKey;
  final String labelAr;

  static AppAccentPreset fromKey(String? key) {
    return AppAccentPreset.values.firstWhere(
      (preset) => preset.storageKey == key,
      orElse: () => AppAccentPreset.trustBlue,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _themeModeKey = 'app_theme_mode';
  static const _accentPresetKey = 'app_accent_preset';

  AppSettingsNotifier()
    : super(
        const AppSettingsState(
          themeMode: ThemeMode.light,
          accentPreset: AppAccentPreset.trustBlue,
        ),
      ) {
    _loadPersistedSettings();
  }

  Future<void> _loadPersistedSettings() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;

    ThemeMode themeMode = ThemeMode.light;
    final storedMode = prefs.getString(_themeModeKey);
    if (storedMode == ThemeMode.dark.name) {
      themeMode = ThemeMode.dark;
    }

    final accent = AppAccentPreset.fromKey(
      prefs.getString(_accentPresetKey),
    );

    if (!mounted) return;
    state = state.copyWith(themeMode: themeMode, accentPreset: accent);
  }

  Future<void> _persistSettings() async {
    final prefs = await _safeGetPrefs();
    if (prefs == null) return;
    await prefs.setString(_themeModeKey, state.themeMode.name);
    await prefs.setString(_accentPresetKey, state.accentPreset.storageKey);
  }

  Future<SharedPreferences?> _safeGetPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
    _persistSettings();
  }

  void setDarkModeEnabled(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleThemeMode() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  /// Reserved for future accent customization UI.
  void setAccentPreset(AppAccentPreset preset) {
    state = state.copyWith(accentPreset: preset);
    _persistSettings();
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((_) {
      return AppSettingsNotifier();
    });
