import 'package:flutter/material.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';

// Theme controller to manage app-wide theme changes
class ThemeController extends ChangeNotifier {
  // Default to light mode
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Initialize theme from preferences
  Future<void> loadTheme() async {
    final isDarkMode = await UserPreferences.getDarkMode();
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Change theme and save preference
  Future<void> setDarkMode(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await UserPreferences.setDarkMode(isDarkMode);
    notifyListeners();
  }
}
