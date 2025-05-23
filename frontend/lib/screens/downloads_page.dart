import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({Key? key}) : super(key: key);

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }
  Future<void> _loadDownloadedFiles() async {
    try {
      final directory = await _getDownloadsDirectory();
      if (directory == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final files = directory.listSync()
        ..sort((a, b) {
          return b.statSync().modified.compareTo(a.statSync().modified);
        });

      setState(() {
        _downloadedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading downloads: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDocDir.path}/Downloads');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      return downloadsDir;
    } catch (e) {
      print('Error getting downloads directory: $e');
      return null;
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Icons.description;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['.mp4', '.mov', '.wmv', '.flv', '.avi', '.mkv'].contains(ext)) {
      return Icons.video_file;
    } else if (['.mp3', '.wav', '.ogg', '.m4a', '.flac'].contains(ext)) {
      return Icons.audio_file;
    } else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(ext)) {
      return Icons.folder_zip;
    } else if (['.apk'].contains(ext)) {
      return Icons.android;
    } else {
      return Icons.insert_drive_file;
    }
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
    } else if (['.mp4', '.mov', '.wmv', '.flv', '.avi', '.mkv'].contains(ext)) {
      return Colors.purple;
    } else if (['.mp3', '.wav', '.ogg', '.m4a', '.flac'].contains(ext)) {
      return Colors.pink;
    } else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(ext)) {
      return Colors.amber.shade800;
    } else if (['.apk'].contains(ext)) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
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

  String _formatLastModified(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _openFile(FileSystemEntity file) async {
    try {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        _showSnackBar('Could not open file: ${result.message}');
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e');
    }
  }

  Future<void> _deleteFile(FileSystemEntity file, int index) async {
    try {
      await file.delete();
      setState(() {
        _downloadedFiles.removeAt(index);
      });
      _showSnackBar('File deleted successfully');
    } catch (e) {
      _showSnackBar('Error deleting file: $e');
    }
  }

  void _showDeleteConfirmationDialog(FileSystemEntity file, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
            'Are you sure you want to delete ${path.basename(file.path)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file, index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
        title: const Text('TeleDrive Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloadedFiles,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _downloadedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_done_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No files downloaded from TeleDrive',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              'Files you download from TeleDrive will appear here'),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: ListView.builder(
                        itemCount: _downloadedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _downloadedFiles[index];
                          final fileName = path.basename(file.path);
                          final stats = file.statSync();
                          final fileSize = stats.size;
                          final lastModified = stats.modified;

                          return ListTile(
                            leading: Icon(
                              _getFileIcon(fileName),
                              color: _getFileIconColor(fileName),
                              size: 40,
                            ),
                            title: Text(fileName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatFileSize(fileSize)),
                                Text(
                                  _formatLastModified(lastModified),
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
                            onTap: () => _openFile(file),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(file, index),
                            ),
                          );
                        },
                      ),
                    ),

          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _openInFileExplorer(),
              icon: const Icon(Icons.folder_open),
              label: const Text('OPEN FILE IN TELEGRAM'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInFileExplorer() async {
    try {
      final downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir != null) {
        final result = await OpenFile.open(downloadsDir.path);
        if (result.type != ResultType.done) {
          _showSnackBar('Could not open file manager: ${result.message}');
        }
      } else {
        _showSnackBar('Could not locate downloads folder');
      }
    } catch (e) {
      _showSnackBar('Error opening file manager: $e');
    }
  }
}