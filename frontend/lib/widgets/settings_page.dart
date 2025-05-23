import 'package:flutter/material.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';
import 'package:telegram_drive/main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? telegramId;
  String? username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      telegramId = await UserPreferences.getTelegramId();
      username = await UserPreferences.getUsername();
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTheme(bool value) async {
    await themeController.setDarkMode(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          username?.isNotEmpty == true
                              ? username![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        username ?? "User",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Telegram ID: $telegramId',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeController.isDarkMode,
                    onChanged: _toggleTheme,
                  ),
                ),

                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'TeleDrive v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }
}
