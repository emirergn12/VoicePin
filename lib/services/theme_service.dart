import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._privateConstructor();
  static final ThemeService instance = ThemeService._privateConstructor();

  static const String _themePrefKey = 'is_dark_mode';

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  /// SharedPreferences'tan kaydedilmiş tema tercihini yükle
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themePrefKey) ?? false;
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('Tema tercihi yüklenemedi: $e');
    }
  }

  /// Karanlık mod tercihini değiştir ve kaydet
  Future<void> setDarkMode(bool isDark) async {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, isDark);
    } catch (e) {
      debugPrint('Tema tercihi kaydedilemedi: $e');
    }
  }

  /// Temayı tersine çevir
  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }
}
