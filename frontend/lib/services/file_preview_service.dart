import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:telegram_drive/models/file_model.dart';
import 'package:telegram_drive/previews/image_preview_screen.dart';


String baseUrl = 'http://192.168.29.229:3000';

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Preparing Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  file.name,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${file.name}';
      final previewFile = File(filePath);

      if (!await previewFile.exists()) {
        final response = await http.get(
          Uri.parse(
              '$baseUrl/api/file/${file.id}?telegramId=$telegramId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          await previewFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }

      Navigator.pop(context);

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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error previewing file: $e')),
      );
    }
  }
}