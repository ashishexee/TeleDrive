import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:telegram_drive/models/file_model.dart';
import 'package:telegram_drive/previews/image_preview_screen.dart';

class FilePreviewService {
  static bool isPreviewable(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    return isImageFile(ext) || isPdfFile(ext);
  }

  static bool isImageFile(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        .contains(extension);
  }

  static bool isPdfFile(String extension) {
    return extension == '.pdf';
  }

  static Future<void> previewFile(
      BuildContext context, FileItem file, String? telegramId) async {
    final ext = path.extension(file.name).toLowerCase();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Preparing Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(file.name, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );

    try {
      // Get temp directory to store preview files
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${file.name}';
      final previewFile = File(filePath);

      // Check if file already exists in cache
      if (!await previewFile.exists()) {
        // Download file for preview
        final response = await http.get(
          Uri.parse(
              'http://192.168.29.229:3000/api/file/${file.id}?telegramId=$telegramId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          // Write file to temp storage
          await previewFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      // Open appropriate preview based on file type
      if (isImageFile(ext)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              filePath: filePath,
              fileName: file.name,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error previewing file: $e')),
      );
    }
  }
}
