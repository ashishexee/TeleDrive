import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:telegram_drive/constants.dart';
import 'package:telegram_drive/models/file_model.dart';
import 'package:telegram_drive/shared_preferences.dart/userData.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:telegram_drive/widgets/app_drawer.dart';
import 'package:telegram_drive/services/file_preview_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = AppConstants.baseUrl;
  String? telegramId;
  String? username;
  bool isLoading = true;
  bool isUploading = false;
  double uploadProgress = 0.0;
  List<FileItem> fileList = [];
  int _selectedIndex = 0;
  final List<String> _categoryTitles = [
    'All',
    'Photos',
    'Documents',
    'Videos',
    'APKs',
    'Others'
  ];
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late PageController _pageController;
  @override
  void initState() {
    super.initState();
    _loadUserDataAndFiles();
    _getStoragePermission();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      print('Storage permission granted: ${status.isGranted}');
    } else if (status.isDenied) {
      status = await Permission.storage.request();
      print('Storage permission denied: ${status.isDenied}');
    } else if (status.isPermanentlyDenied) {
      print(
          'Storage permission permanently denied: ${status.isPermanentlyDenied}');
      await openAppSettings();
    } else if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    } else if (await Permission.videos.isDenied) {
      await Permission.videos.request();
    } else if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }
  }

  Future<void> _loadUserDataAndFiles() async {
    await _loadUserData();
    if (telegramId != null) {
      await _loadUserFiles();
    }
  }

  Future<void> _loadUserData() async {
    try {
      telegramId = await UserPreferences.getTelegramId();
      username = await UserPreferences.getUsername();

      print('Loaded user data: ID=$telegramId, username=$username');

      if (telegramId == null || telegramId!.isEmpty) {
        print('Warning: User ID is missing. You might need to login again.');
      }
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

  Future<void> _loadUserFiles() async {
    if (telegramId == null || telegramId!.isEmpty) {
      print('Cannot load files: Telegram ID is null or empty');
      return;
    }
    try {
      print('Loading files for user: $telegramId');
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse('$baseUrl/api/files?telegramId=$telegramId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['files'] != null) {
          setState(() {
            fileList = List<FileItem>.from(
                data['files'].map((file) => FileItem.fromJson(file)));
            print('Loaded ${fileList.length} files');
          });
        } else {
          print('Server returned success=false or null files');
        }
      } else {
        print('Failed to load files. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading files: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple:
          true, // change this to false is problems( telegram might ban the bot for abuse )
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    final fileSizeMB = fileSize / (1024 * 1024);
    if (fileSizeMB > 50) {
      _showSnackBar(
          'File too large (${fileSizeMB.toStringAsFixed(1)} MB). Maximum size: 50MB');
      // cannot upload files of size greater than 50 mb
      return;
    }
    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });
    try {
      if (fileSizeMB > 100) {
        _showSnackBar(
            'Uploading a ${fileSizeMB.toStringAsFixed(1)}MB file. This may take several minutes.');
      }
      final url = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', url);

      final fileStream = file.openRead();
      int bytesSent = 0;
      final progressStream = fileStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            final progress = bytesSent / fileSize;
            if (mounted) {
              setState(() {
                uploadProgress = progress;
              });
            }
            sink.add(data);
          },
        ),
      );

      final multipartFile = http.MultipartFile(
        'file',
        progressStream.cast<List<int>>(),
        fileSize,
        filename: fileName,
      );
      request.files.add(multipartFile);

      request.fields['telegramId'] = telegramId ?? '';
      request.fields['filename'] = fileName;

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 30),
        onTimeout: () {
          throw TimeoutException('Upload timed out - check your connection');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          final newFile = FileItem(
            id: responseData['fileId'],
            name: fileName,
            size: fileSize,
            uploadDate: DateTime.now(),
          );

          setState(() {
            fileList.add(newFile);
            isUploading = false;
            uploadProgress = 1.0;
          });

          _showSnackBar('File uploaded successfully!');
          _loadUserFiles();
        } else {
          _showSnackBar('Upload failed: ${responseData['message']}');
          setState(() => isUploading = false);
        }
      } else {
        _showSnackBar('Upload failed with status ${response.statusCode}');
        setState(() => isUploading = false);
      }
    } catch (e) {
      print('Upload error: $e');
      _showSnackBar('Error uploading file: $e');
      setState(() => isUploading = false);
    }
  }

  Future<void> _downloadFile(FileItem file) async {
    _showSnackBar('Requesting download...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/download/${file.id}?telegramId=$telegramId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['message'] != null) {
          _showSnackBar('File sent to your Telegram chat!');
        } else {
          _showSnackBar('Download failed: ${data['message']}');
        }
      } else {
        _showSnackBar('Download request failed');
      }
    } catch (e) {
      _showSnackBar('Error requesting download: $e');
    }
  }

  Future<void> _downloadFileDirectly(FileItem file) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    } else if (status.isDenied) {
      status = await Permission.storage.request();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    try {
      _showSnackBar('Downloading ${file.name}...');

      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDocDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '${downloadsDir.path}/${file.name}';
      print('Downloading file to: $filePath');

      final File downloadFile = File(filePath);

      final response = await http.get(
        Uri.parse('$baseUrl/api/file/${file.id}?telegramId=$telegramId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await downloadFile.writeAsBytes(response.bodyBytes);

        _showSnackBar('${file.name} downloaded successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File downloaded successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      } else {
        _showSnackBar('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error downloading file: $e');
    }
  }

  Future<void> _deleteFile(FileItem file) async {
    try {
      bool confirmDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Text('Delete File'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to delete'),
                  const SizedBox(height: 8),
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can see the deleted file in RECYCLE BIN.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('DELETE'),
                ),
              ],
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ) ??
          false;

      if (!confirmDelete) return;

      final response = await http.delete(
        Uri.parse('$baseUrl/api/file/${file.id}?telegramId=$telegramId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            fileList.removeWhere((f) => f.id == file.id);
          });
          _showSnackBar('${file.name} deleted successfully');
        } else {
          _showSnackBar('Delete failed: ${data['message']}');
        }
      } else {
        _showSnackBar('Delete failed with status ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error deleting file: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: AppDrawer(
            username: username,
            telegramId: telegramId,
            fileList: fileList,
            refreshFiles: _refreshFiles,
            changeTab: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            showSnackBar: _showSnackBar),
        appBar: AppBar(
          leading: _isSearchActive
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearchActive = false;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          title: _isSearchActive
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                        color: Theme.of(context)
                            .appBarTheme
                            .foregroundColor
                            ?.withOpacity(0.6)),
                  ),
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : Text(_categoryTitles[_selectedIndex]),
          actions: [
            if (_isSearchActive)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearchActive = true;
                  });
                },
              ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Upload progress indicator (if uploading)
                  if (isUploading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Uploading file...'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: uploadProgress),
                        ],
                      ),
                    ),

                  // Files list with swipe navigation
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedIndex = index;
                          if (_isSearchActive) {
                            _isSearchActive = false;
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                      },
                      children: [
                        _buildFileList(0), // All
                        _buildFileList(1), // Photos
                        _buildFileList(2), // Docs
                        _buildFileList(3), // Videos
                        _buildFileList(4), // APKs
                        _buildFileList(5), // Others
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              if (_isSearchActive) {
                _isSearchActive = false;
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'All',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library),
              label: 'Photos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Docs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.android),
              label: 'APKs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Others',
            ),
          ],
        ),
        floatingActionButton: isUploading
            ? null
            : FloatingActionButton.extended(
                onPressed: _uploadFile,
                icon: const Icon(Icons.add),
                label: const Text('UPLOAD'),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat);
  }

  Future<void> _refreshFiles() async {
    if (mounted) {
      await _loadUserDataAndFiles();
    }
  }

  Widget _buildFileList([int? index]) {
    final categoryIndex = index ?? _selectedIndex;
    final filteredFiles = _getFilteredFilesForCategory(categoryIndex);

    return RefreshIndicator(
      onRefresh: _refreshFiles,
      child: filteredFiles.isEmpty
          ? _buildEmptyView(categoryIndex)
          : categoryIndex == 0
              ? ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    final isImage = _isImageFile(file.name);

                    return ListTile(
                      leading: Icon(_getFileIcon(file.name),
                          color: _getFileIconColor(file.name)),
                      title: Text(file.name),
                      subtitle: Text(_formatFileSize(file.size)),
                      onTap: isImage
                          ? () => FilePreviewService.previewFile(
                              context, file, telegramId)
                          : null,
                      onLongPress: () => _deleteFile(file),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.download_for_offline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'Download to device',
                            onPressed: () async {
                              await _downloadFileDirectly(file);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.telegram,
                              color: const Color(0xFF0088CC),
                            ),
                            tooltip: 'Send to Telegram',
                            onPressed: () => _downloadFile(file),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : categoryIndex == 1
                  ? _buildImageGrid(filteredFiles)
                  : _buildGenericFileGrid(filteredFiles),
    );
  }

  List<FileItem> _getFilteredFilesForCategory(int categoryIndex) {
    List<FileItem> result = [];
    if (categoryIndex == 0) {
      result = List.from(fileList);
    } else {
      final List<List<String>> categoryExtensions = [
        [], // All
        ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'], // Images
        [
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.ppt',
          '.pptx',
          '.txt'
        ], // Documents
        [
          '.mp4',
          '.mkv',
          '.avi',
          '.mov',
          '.wmv',
          '.flv',
          '.webm',
          '.m4v'
        ], // Videos
        ['.apk'], // APKs
        [] // Others
      ];

      if (categoryIndex >= 1 && categoryIndex <= 4) {
        final extensions = categoryExtensions[categoryIndex];
        result = fileList.where((file) {
          final ext = path.extension(file.name).toLowerCase();
          return extensions.contains(ext);
        }).toList();
      } else if (categoryIndex == 5) {
        final allKnownExtensions = [
          ...categoryExtensions[1],
          ...categoryExtensions[2],
          ...categoryExtensions[3],
          ...categoryExtensions[4],
        ];

        result = fileList.where((file) {
          final ext = path.extension(file.name).toLowerCase();
          return !allKnownExtensions.contains(ext);
        }).toList();
      }
    }

    if (_isSearchActive && _searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((file) => file.name.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  // Update the empty view method to take a category index parameter
  Widget _buildEmptyView([int? categoryIndex]) {
    final index = categoryIndex ?? _selectedIndex;
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height / 3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSearchActive
                    ? Icons.search_off
                    : index == 0
                        ? Icons.cloud_upload
                        : index == 1
                            ? Icons.photo_library
                            : index == 2
                                ? Icons.description
                                : index == 3
                                    ? Icons.video_library
                                    : index == 4
                                        ? Icons.android
                                        : Icons.folder,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _isSearchActive
                    ? 'No results found'
                    : index == 0
                        ? 'No files yet'
                        : 'No ${_categoryTitles[index]} found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isSearchActive
                    ? 'Try different search terms'
                    : index == 0
                        ? 'Upload your first file using the button below'
                        : 'Files will appear here when you upload them',
              ),
              const SizedBox(height: 16),
              // Only show buttons for search mode or "All" tab
              if (_isSearchActive)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSearchActive = false;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  child: const Text('Clear Search'),
                )
              else if (index == 0) // Only show refresh button on "All" tab
                ElevatedButton(
                  onPressed: () => _refreshFiles(),
                  child: const Text('Refresh'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericFileGrid(List<FileItem> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            // No onTap handler for generic files
            onLongPress: () => _deleteFile(file),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // File icon (takes up space similar to thumbnail)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                      child: Icon(
                        _getFileIcon(file.name),
                        size: 64,
                        color: _getFileIconColor(file.name),
                      ),
                    ),
                  ),
                ),

                // File info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(file.size),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Download button
                      ElevatedButton.icon(
                        onPressed: () => _downloadFileDirectly(file),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text("Save"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(10, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),

                      // Telegram button
                      OutlinedButton.icon(
                        onPressed: () => _downloadFile(file),
                        icon: const Icon(Icons.telegram, size: 16),
                        label: const Text("Share"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(10, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this helper method to get color for file icons based on file type
  Color _getFileIconColor(String fileName) {
    final ext = path.extension(fileName).toLowerCase();

    // Documents
    if (['.pdf'].contains(ext)) {
      return Colors.red;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Colors.blue.shade700;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Colors.green.shade700;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Colors.orange;
    } else if (['.txt'].contains(ext)) {
      return Colors.grey.shade600;
    }
    // Videos
    else if (['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv'].contains(ext)) {
      return Colors.purple;
    }
    // APK
    else if (['.apk'].contains(ext)) {
      return Colors.green;
    }
    // Audio
    else if (['.mp3', '.wav', '.flac', '.ogg', '.m4a'].contains(ext)) {
      return Colors.pinkAccent;
    }
    // Archives
    else if (['.zip', '.rar', '.7z', '.gz', '.tar'].contains(ext)) {
      return Colors.amber.shade700;
    }
    // Default
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.blueGrey;
  }

  // Create a new method for the empty state view

  // Add this new method to build the image grid
  Widget _buildImageGrid(List<FileItem> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () =>
                FilePreviewService.previewFile(context, file, telegramId),
            onLongPress: () => _deleteFile(file), // Add this line
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildImageThumbnail(file),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatFileSize(file.size),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _downloadFileDirectly(file),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text("Save"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(10, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _downloadFile(file),
                        icon: const Icon(Icons.telegram, size: 16),
                        label: const Text("Share"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(10, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageThumbnail(FileItem file) {
    return FutureBuilder<Widget>(
      future: _getThumbnailWidget(file),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        } else {
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.image, size: 40, color: Colors.grey.shade400),
            ),
          );
        }
      },
    );
  }

  Future<Widget> _getThumbnailWidget(FileItem file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailDir = Directory('${tempDir.path}/thumbnails');
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create();
      }

      final thumbnailPath = '${thumbnailDir.path}/${file.id}_thumb';
      final thumbnailFile = File(thumbnailPath);

      if (await thumbnailFile.exists()) {
        return Image.file(
          thumbnailFile,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: Colors.grey.shade400),
            );
          },
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/thumbnail/${file.id}?telegramId=$telegramId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await thumbnailFile.writeAsBytes(response.bodyBytes);

        return Image.memory(
          response.bodyBytes,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: Colors.grey.shade400),
            );
          },
        );
      } else {
        return Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
        );
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image, size: 40, color: Colors.grey.shade400),
      );
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
    } else if (['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v']
        .contains(ext)) {
      return Icons.video_file;
    } else if (['.mp3', '.wav', '.flac', '.ogg', '.m4a', '.aac']
        .contains(ext)) {
      return Icons.audio_file;
    } else if (['.apk'].contains(ext)) {
      return Icons.android;
    }
    return Icons.insert_drive_file;
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

  bool _isImageFile(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext);
  }
}
