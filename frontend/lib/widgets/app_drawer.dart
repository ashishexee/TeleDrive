import 'package:flutter/material.dart';
import 'package:telegram_drive/auth/login_page.dart';
import 'package:telegram_drive/models/file_model.dart';
import 'package:telegram_drive/screens/bin_page.dart';
import 'package:telegram_drive/screens/downloads_page.dart';
import 'package:telegram_drive/widgets/settings_page.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';

class AppDrawer extends StatelessWidget {
  final String? username;
  final String? telegramId;
  final List<FileItem> fileList;
  final Function refreshFiles;
  final Function(int) changeTab;
  final Function showSnackBar;

  const AppDrawer({
    Key? key,
    required this.username,
    required this.telegramId,
    required this.fileList,
    required this.refreshFiles,
    required this.changeTab,
    required this.showSnackBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username ?? 'TeleDrive User'),
            accountEmail: Text('ID: $telegramId'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                (username != null && username!.isNotEmpty)
                    ? username![0].toUpperCase()
                    : 'T',
                style: const TextStyle(fontSize: 24.0, color: Colors.white),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Storage',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatFileSize(_calculateTotalSize()),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.05,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${fileList.length} files',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    Text(
                      'Unlimited storage',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              showSnackBar('Favorites feature coming soon!');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Downloads'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DownloadsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
            ),
            title: const Text('Recycle Bin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BinPage(
                    onFileRestored: () => refreshFiles(), // Pass the callback
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'How to use TeleDrive',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Getting Started Section
                Text('Getting Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    )),
                const SizedBox(height: 12),
                _buildHelpItem(context, Icons.cloud_upload,
                    'Upload files by tapping the UPLOAD button in the bottom right corner.'),
                _buildHelpItem(context, Icons.folder_outlined,
                    'Files are organized by categories. Use the bottom tabs to navigate between them.'),
                _buildHelpItem(context, Icons.search,
                    'Search for files by name using the search bar at the top.'),

                const SizedBox(height: 20),

                Text('File Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    )),
                const SizedBox(height: 12),
                _buildHelpItem(context, Icons.touch_app,
                    'Preview files by tapping on them. Images, PDFs, and text files can be viewed directly.'),
                _buildHelpItem(context, Icons.more_vert,
                    'Access file options like Share, Download, or Delete by tapping the three-dot menu.'),
                _buildHelpItem(context, Icons.download_rounded,
                    'Download files to your device or send them directly to your Telegram contacts.'),

                const SizedBox(height: 20),

                Text('Advanced Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    )),
                const SizedBox(height: 12),
                _buildHelpItem(context, Icons.favorite,
                    'Mark important files as favorites for quick access.'),
                _buildHelpItem(context, Icons.folder_special,
                    'Create folders to organize your files better.'),
                _buildHelpItem(context, Icons.sync,
                    'Pull down to refresh and get the latest updates to your files.'),

                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Got it!',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TeleDrive',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Store and manage your files securely using Telegram as your personal cloud storage solution. Access your files from any device, anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '©2025 TeleDrive',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(120, 40),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to logout? You will need to reconnect your Telegram account to use TeleDrive again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await UserPreferences.clearUserData();
                        Navigator.pop(context);

                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                            (route) => false);
                        showSnackBar('Logged out successfully.');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();

    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }

  int _calculateTotalSize() {
    return fileList.fold(0, (sum, file) => sum + file.size);
  }
}
