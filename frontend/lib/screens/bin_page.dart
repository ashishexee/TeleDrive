import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:telegram_drive/models/file_model.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';

class BinPage extends StatefulWidget {
  final Function? onFileRestored; // Add this callback parameter

  const BinPage({
    Key? key,
    this.onFileRestored,
  }) : super(key: key);

  @override
  State<BinPage> createState() => _BinPageState();
}

class _BinPageState extends State<BinPage> {
  List<FileItem> _deletedFiles = [];
  bool _isLoading = true;
  String? telegramId;

  @override
  void initState() {
    super.initState();
    _loadDeletedFiles();
  }

  Future<void> _loadUserData() async {
    telegramId = await UserPreferences.getTelegramId();
  }

  Future<void> _loadDeletedFiles() async {
    setState(() {
      _isLoading = true;
    });

    await _loadUserData();

    if (telegramId == null) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('User ID not found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.29.229:3000/api/bin?telegramId=$telegramId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['files'] != null) {
          setState(() {
            _deletedFiles = List<FileItem>.from(
                data['files'].map((file) => FileItem.fromJson(file)));
          });
        }
      } else {
        _showSnackBar('Failed to load deleted files');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreFile(FileItem file) async {
    try {
      _showSnackBar('Restoring ${file.name}...');

      final response = await http.post(
        Uri.parse(
            'http://192.168.29.229:3000/api/bin/restore/${file.id}?telegramId=$telegramId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _deletedFiles.removeWhere((f) => f.id == file.id);
          });
          _showSnackBar('${file.name} restored successfully');

          // Call the callback function if it exists
          if (widget.onFileRestored != null) {
            widget.onFileRestored!();
          }
        } else {
          _showSnackBar('Restore failed: ${data['message']}');
        }
      } else {
        _showSnackBar('Failed to restore file');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _permanentlyDeleteFile(FileItem file) async {
    // Show confirmation dialog first
    bool confirmDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Permanently'),
            content: Text(
                'Are you sure you want to permanently delete ${file.name}? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete Forever',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      _showSnackBar('Permanently deleting ${file.name}...');

      final response = await http.delete(
        Uri.parse(
            'http://192.168.29.229:3000/api/bin/${file.id}?telegramId=$telegramId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _deletedFiles.removeWhere((f) => f.id == file.id);
          });
          _showSnackBar('${file.name} permanently deleted');
        } else {
          _showSnackBar('Delete failed: ${data['message']}');
        }
      } else {
        _showSnackBar('Failed to delete file');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = path.extension(fileName).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx', '.txt', '.rtf'].contains(ext)) {
      return Icons.description;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv'].contains(ext)) {
      return Icons.video_file;
    } else if (['.apk'].contains(ext)) {
      return Icons.android;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(String fileName) {
    final ext = path.extension(fileName).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Colors.blue;
    } else if (['.pdf'].contains(ext)) {
      return Colors.red;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Colors.blue.shade700;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Colors.green;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Colors.orange;
    } else if (['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv'].contains(ext)) {
      return Colors.purple;
    } else if (['.apk'].contains(ext)) {
      return Colors.green;
    }
    return Colors.grey;
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

  String _formatDeletedDate(DateTime deletedAt) {
    final now = DateTime.now();
    final difference = now.difference(deletedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recycle Bin is empty',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Deleted files will appear here and be stored for 30 days',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _deletedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _deletedFiles[index];

                    return Dismissible(
                      key: Key(file.id),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.restore, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_forever,
                            color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          // Restore
                          _restoreFile(file);
                        } else {
                          // Delete permanently
                          _permanentlyDeleteFile(file);
                        }
                      },
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Confirm permanent deletion
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Permanently'),
                              content: Text(
                                  'Are you sure you want to permanently delete ${file.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete Forever',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        }
                        return true;
                      },
                      child: ListTile(
                        leading: Icon(
                          _getFileIcon(file.name),
                          color: _getFileIconColor(file.name),
                          size: 40,
                        ),
                        title: Text(file.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatFileSize(file.size)),
                            Text(
                              'Deleted ${_formatDeletedDate(file.deletedAt ?? DateTime.now())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Restore button
                            IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: 'Restore',
                              onPressed: () => _restoreFile(file),
                            ),
                            // Delete permanently button
                            IconButton(
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.red),
                              tooltip: 'Delete permanently',
                              onPressed: () => _permanentlyDeleteFile(file),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
