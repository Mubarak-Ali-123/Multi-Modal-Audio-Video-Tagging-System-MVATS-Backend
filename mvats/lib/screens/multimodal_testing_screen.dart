import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:video_player/video_player.dart';
import '../theme/theme_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/background_blobs.dart';
import '../services/video_classifier_service.dart';

class MultimodalTestingScreen extends StatefulWidget {
  const MultimodalTestingScreen({super.key});

  @override
  State<MultimodalTestingScreen> createState() =>
      _MultimodalTestingScreenState();
}

class _MultimodalTestingScreenState extends State<MultimodalTestingScreen>
    with SingleTickerProviderStateMixin {
  final VideoClassifierService _classifier = VideoClassifierService();

  // Video state
  String? _videoFilePath;
  String? _videoFileName;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  // Audio state
  String? _audioFilePath;
  String? _audioFileName;

  // Processing state
  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // Video methods
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      await _handleVideoSelected(file.path!, file.name);
    }
  }

  Future<void> _handleVideoSelected(String path, String name) async {
    setState(() {
      _videoFilePath = path;
      _videoFileName = name;
      _result = null;
      _videoInitialized = false;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));

    try {
      await _videoController!.initialize();
      setState(() {
        _videoInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _clearVideo() {
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _videoFilePath = null;
      _videoFileName = null;
      _result = null;
      _videoInitialized = false;
    });
  }

  // Audio methods
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      _handleAudioSelected(file.path!, file.name);
    }
  }

  void _handleAudioSelected(String path, String name) {
    setState(() {
      _audioFilePath = path;
      _audioFileName = name;
      _result = null;
    });
  }

  void _clearAudio() {
    setState(() {
      _audioFilePath = null;
      _audioFileName = null;
      _result = null;
    });
  }

  // Process multimodal
  Future<void> _processMultimodal() async {
    if (_videoFilePath == null && _audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one file')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final result = await _classifier.classifyMultimodal(
        videoPath: _videoFilePath,
        audioPath: _audioFilePath,
      );
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = {
          'error': true,
          'message': 'Error processing files: $e',
        };
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = _videoFilePath != null || _audioFilePath != null;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          BackgroundBlobs(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildNavbar(context),
                Expanded(
                  child: hasFile
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Column(
                              children: [
                                _buildDropZone(scheme, isDark),
                                const SizedBox(height: 20),
                                if (_videoFilePath != null)
                                  _buildVideoPreview(scheme),
                                if (_videoFilePath != null &&
                                    _audioFilePath != null)
                                  const SizedBox(height: 20),
                                if (_audioFilePath != null)
                                  _buildAudioPreview(scheme),
                                const SizedBox(height: 20),
                                _buildActionButtons(scheme),
                                if (_result != null) ...[
                                  const SizedBox(height: 20),
                                  _buildResults(scheme, isDark),
                                ],
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: _buildDropZone(scheme, isDark),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
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
            "Upload - Multimodal",
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

  Widget _buildDropZone(ColorScheme scheme, bool isDark) {
    return DropTarget(
      onDragDone: (details) async {
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          final ext = file.name.toLowerCase();
          // Determine if it's video or audio based on extension
          if (ext.endsWith('.mp4') ||
              ext.endsWith('.avi') ||
              ext.endsWith('.mov') ||
              ext.endsWith('.mkv')) {
            await _handleVideoSelected(file.path, file.name);
          } else {
            _handleAudioSelected(file.path, file.name);
          }
        }
      },
      child: GlassContainer(
        opacity: 0.22,
        padding: const EdgeInsets.all(26),
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 440,
          child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text("Video"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickAudio,
                    icon: const Icon(Icons.audiotrack, size: 18),
                    label: const Text("Audio"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ColorScheme scheme) {
    return SizedBox(
      width: 440,
      child: GlassContainer(
        opacity: 0.18,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.movie_outlined, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _videoFileName ?? 'Video',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: scheme.error, size: 18),
                  onPressed: _clearVideo,
                  tooltip: 'Remove video',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (_videoInitialized && _videoController != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreview(ColorScheme scheme) {
    return SizedBox(
      width: 440,
      child: GlassContainer(
        opacity: 0.18,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.audiotrack, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _audioFileName ?? 'Audio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: scheme.error, size: 18),
                  onPressed: _clearAudio,
                  tooltip: 'Remove audio',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: _WaveformPainter(
                      progress: _waveController.value,
                      color: scheme.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme scheme) {
    final hasFiles = _videoFilePath != null || _audioFilePath != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing || !hasFiles ? null : _processMultimodal,
          icon: _isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : const Icon(Icons.analytics_outlined),
          label: Text(_isProcessing ? "Processing..." : "Classify Multimodal"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5592),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(ColorScheme scheme, bool isDark) {
    final isError = _result?['error'] == true;
    final isDemo = _result?['isDemo'] == true;

    return SizedBox(
      width: 440,
      child: GlassContainer(
        opacity: 0.22,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? scheme.error : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isError ? "Error" : "Multimodal Classification Result",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (isDemo) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "DEMO",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (isError)
              Text(
                _result?['message'] ?? 'Unknown error',
                style: TextStyle(color: scheme.error),
              )
            else ...[
              _buildResultRow(
                "Predicted Class",
                _result?['predictedClass']?.toString().toUpperCase() ?? 'N/A',
                scheme,
                isHighlighted: true,
              ),
              const SizedBox(height: 12),
              _buildResultRow(
                "Confidence",
                "${((_result?['confidence'] ?? 0) * 100).toStringAsFixed(1)}%",
                scheme,
              ),
              const SizedBox(height: 12),
              _buildResultRow(
                "Input Type",
                _result?['type']?.toString().toUpperCase() ?? 'MULTIMODAL',
                scheme,
              ),
              if (_result?['topPredictions'] != null) ...[
                const SizedBox(height: 20),
                Text(
                  "Top Predictions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_result?['topPredictions'] as List).map((pred) {
                  final confidence = (pred['confidence'] ?? 0) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            pred['class'] ?? 'Unknown',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: confidence / 100,
                              backgroundColor:
                                  scheme.onSurface.withValues(alpha: 0.1),
                              color: const Color(0xFFFF5592),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            "${confidence.toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              if (isDemo && _result?['message'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _result!['message'],
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, ColorScheme scheme,
      {bool isHighlighted = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isHighlighted ? 16 : 12,
              vertical: isHighlighted ? 8 : 4,
            ),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFFFF5592).withValues(alpha: 0.2)
                  : scheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isHighlighted ? 12 : 8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color:
                    isHighlighted ? const Color(0xFFFF5592) : scheme.onSurface,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                fontSize: isHighlighted ? 14 : 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for waveform animation
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 30;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final phase = (progress * 2 * 3.14159) + (i * 0.2);
      final amplitude = (size.height / 3) * (0.3 + 0.7 * ((i % 4 + 1) / 4));
      final y = size.height / 2 + amplitude * _sin(phase);

      canvas.drawLine(
        Offset(x, size.height / 2 - y.abs() / 2),
        Offset(x, size.height / 2 + y.abs() / 2),
        paint,
      );
    }
  }

  double _sin(double x) {
    x = x % (2 * 3.14159);
    if (x > 3.14159) x -= 2 * 3.14159;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
