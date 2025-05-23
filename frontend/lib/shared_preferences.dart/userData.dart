import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  // Use standard key names
  static const String _keyTelegramId = 'telegram_id';
  static const String _keyUsername = 'username';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyDarkMode = 'dark_mode';

  // Save user data - standardized name and implementation
  static Future<void> saveUserData({
    required String telegramId,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTelegramId, telegramId);
    await prefs.setString(_keyUsername, username);
    await prefs.setBool(_keyIsLoggedIn, true);

    // Debug print to verify data is being saved
    print('Saving user data: ID=$telegramId, username=$username');
  }

  // Get telegram ID - standardized naming
  static Future<String?> getTelegramId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTelegramId);
  }

  // Get username - standardized naming
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Theme settings
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // Clear user data for logout
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTelegramId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyIsLoggedIn);
    // Note: We don't clear theme preferences on logout
  }
}
