import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String filePath;
  final String fileName;
  final bool isNetworkImage;

  const ImagePreviewScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
    this.isNetworkImage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image saved to Downloads')),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: PhotoView(
          imageProvider: isNetworkImage
              ? NetworkImage(filePath)
              : FileImage(File(filePath)) as ImageProvider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}
