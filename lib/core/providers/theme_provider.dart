import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefKey = 'is_dark_theme';

final appThemeProvider = StateNotifierProvider<AppThemeNotifier, ThemeMode>((
  ref,
) {
  return AppThemeNotifier()..loadTheme();
});

class AppThemeNotifier extends StateNotifier<ThemeMode> {
  AppThemeNotifier() : super(ThemeMode.dark);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkTheme = prefs.getBool(_themePrefKey) ?? true;
    state = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkTheme(bool isDarkTheme) async {
    state = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, isDarkTheme);
  }

  Future<void> toggleTheme() async {
    final isDarkTheme = state != ThemeMode.dark;
    await setDarkTheme(isDarkTheme);
  }
}
