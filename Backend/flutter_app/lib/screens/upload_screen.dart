import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/theme_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/background_blobs.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  final String type;

  const UploadScreen({super.key, required this.type});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? selectedFile;
  bool isUploading = false;
  bool uploadSuccess = false;
  Map<String, dynamic>? uploadResponse;

  String _getFileType() {
    if (widget.type.toLowerCase().contains('audio')) {
      return 'audio';
    } else if (widget.type.toLowerCase().contains('video')) {
      return 'video';
    } else {
      return 'fusion';
    }
  }

  List<String> _getAllowedExtensions() {
    if (widget.type.toLowerCase().contains('audio')) {
      return ['mp3', 'wav', 'aac', 'flac', 'ogg'];
    } else if (widget.type.toLowerCase().contains('video')) {
      return ['mp4', 'avi', 'mov', 'mkv'];
    } else {
      return ['mp3', 'wav', 'aac', 'flac', 'ogg', 'mp4', 'avi', 'mov', 'mkv'];
    }
  }

  Future<void> _browseFiles() async {
    try {
      // For better compatibility on Windows, be explicit about options
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _getAllowedExtensions(),
        allowMultiple: false,
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file extension
        if (!_isValidFileType(file.name)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid file type. Please select a valid ${widget.type.toLowerCase()} file.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() {
          selectedFile = file;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: ${selectedFile!.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _isValidFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final validExtensions = _getAllowedExtensions();
    return validExtensions.contains(extension);
  }

  Future<void> _browseAllFiles() async {
    try {
      // Browse all files without extension filtering
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file extension
        if (!_isValidFileType(file.name)) {
          if (mounted) {
            // Show warning but allow selection
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('File Type Warning'),
                content: Text(
                  'The selected file (${file.name}) may not be a valid ${widget.type.toLowerCase()} file.\n\n'
                  'Valid formats: ${_getAllowedExtensions().join(', ')}\n\n'
                  'Continue anyway?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) return;
          }
        }

        setState(() {
          selectedFile = file;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: ${selectedFile!.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (selectedFile == null || selectedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadSuccess = false;
    });

    try {
      final response = await ApiService().uploadMedia(
        selectedFile!.path!,
        _getFileType(),
      );

      if (mounted) {
        setState(() {
          uploadSuccess = true;
          uploadResponse = response;
          isUploading = false;
        });

        // Save to history
        await _saveUploadToHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _showUploadResult();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading = false;
        });

        String errorMessage = 'Upload failed. Please try again.';
        if (e is Exception) {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showUploadResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Successful'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${selectedFile!.name}'),
              const SizedBox(height: 12),
              if (uploadResponse != null) ...[
                Text('Media ID: ${uploadResponse?['mediaId'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Type: ${uploadResponse?['mediaType'] ?? 'N/A'}'),
              ],
              const SizedBox(height: 16),
              const Text('Your file is now available in the system.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      selectedFile = null;
      uploadSuccess = false;
      uploadResponse = null;
    });
  }

  Future<void> _saveUploadToHistory() async {
    if (uploadResponse == null || selectedFile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final uploadsList = prefs.getStringList('uploads') ?? [];

      final uploadData = {
        'fileName': selectedFile!.name,
        'fileType': _getFileType(),
        'mediaId': uploadResponse!['mediaId'],
        'uploadTime': DateTime.now().toString(),
        'size': selectedFile!.size,
      };

      uploadsList.add(jsonEncode(uploadData));
      await prefs.setStringList('uploads', uploadsList);
    } catch (e) {
      // Silent fail for history saving
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          BackgroundBlobs(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _GlassNavbar(title: "Upload - ${widget.type}"),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: GlassContainer(
                        opacity: 0.22,
                        padding: const EdgeInsets.all(26),
                        borderRadius: BorderRadius.circular(28),
                        child: SizedBox(
                          width: 440,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedFile == null)
                                _buildFileSelector(scheme)
                              else
                                _buildFilePreview(scheme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFileSelector(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 78,
          color: scheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          "Drag & Drop or Locate File",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Supported formats depend on the selected mode.\n"
          "This is the upload step for your MVATS testing.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 26),
        OutlinedButton.icon(
          onPressed: _browseFiles,
          icon: const Icon(Icons.folder_open),
          label: const Text("Browse Files"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 26,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _browseAllFiles,
          icon: const Icon(Icons.folder),
          label: const Text("Browse All Files"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 70,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        Text(
          "File Selected",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Name:",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedFile!.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                "Size:",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${(selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        if (isUploading)
          Column(
            children: [
              CircularProgressIndicator(
                color: scheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                "Uploading...",
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.clear),
                label: const Text("Change File"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _uploadFile,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _GlassNavbar extends StatelessWidget {
  final String title;

  const _GlassNavbar({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context);
    final scheme = Theme.of(context).colorScheme;

    return GlassContainer(
      opacity: 0.16,
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            color: scheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: theme.toggleTheme,
          ),
        ],
      ),
    );
  }
}
