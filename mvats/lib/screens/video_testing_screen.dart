import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:video_player/video_player.dart';
import '../theme/theme_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/background_blobs.dart';
import '../services/video_classifier_service.dart';

class VideoTestingScreen extends StatefulWidget {
  const VideoTestingScreen({super.key});

  @override
  State<VideoTestingScreen> createState() => _VideoTestingScreenState();
}

class _VideoTestingScreenState extends State<VideoTestingScreen> {
  final VideoClassifierService _classifier = VideoClassifierService();

  String? _selectedFilePath;
  String? _fileName;
  bool _isProcessing = false;
  Map<String, dynamic>? _result;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _multiLabelMode = false; // Toggle for multi-label scene detection

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      _handleFileSelected(file.path!, file.name);
    }
  }

  Future<void> _handleFileSelected(String path, String name) async {
    setState(() {
      _selectedFilePath = path;
      _fileName = name;
      _result = null;
      _videoInitialized = false;
    });

    // Initialize video preview
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

  Future<void> _processVideo() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final result = await _classifier.classifyVideo(
        _selectedFilePath!,
        multiLabel: _multiLabelMode,
      );
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = {
          'error': true,
          'message': 'Error processing video: $e',
        };
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _clearSelection() {
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _selectedFilePath = null;
      _fileName = null;
      _result = null;
      _videoInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = _selectedFilePath != null;

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
                                _buildVideoPreview(scheme),
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
            "Upload - Video Only",
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
          _handleFileSelected(file.path, file.name);
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
              OutlinedButton.icon(
                onPressed: _pickFile,
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
                    _fileName ?? 'Selected Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: scheme.error, size: 20),
                  onPressed: _clearSelection,
                  tooltip: 'Remove video',
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
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
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

  Widget _buildActionButtons(ColorScheme scheme) {
    return Column(
      children: [
        // Multi-label toggle
        SizedBox(
          width: 440,
          child: GlassContainer(
            opacity: 0.15,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  color: scheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Multi-Scene Detection",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        "Detect multiple scenes in video",
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _multiLabelMode,
                  onChanged: (value) {
                    setState(() {
                      _multiLabelMode = value;
                      _result = null; // Clear previous results
                    });
                  },
                  activeColor: scheme.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Classify button
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _processVideo,
          icon: _isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Icon(_multiLabelMode ? Icons.layers : Icons.analytics_outlined),
          label: Text(_isProcessing
              ? (_multiLabelMode ? "Analyzing Scenes..." : "Processing...")
              : (_multiLabelMode ? "Detect Scenes" : "Classify Video")),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
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
    final isMultilabel = _result?['type'] == 'video_multilabel';

    // Use wider container for multi-label results to show tiles properly
    final containerWidth = isMultilabel ? 520.0 : 440.0;

    return SizedBox(
      width: containerWidth,
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
                  isError
                      ? Icons.error_outline
                      : (isMultilabel
                          ? Icons.layers
                          : Icons.check_circle_outline),
                  color: isError ? scheme.error : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isError
                        ? "Error"
                        : (isMultilabel
                            ? "Multi-Scene Detection"
                            : "Classification Result"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (isDemo) ...[
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
            else if (isMultilabel) ...[
              // Multi-label results
              _buildMultiLabelResults(scheme),
            ] else ...[
              // Single-label results (existing code)
              _buildSingleLabelResults(scheme),
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
        ),
      ),
    );
  }

  Widget _buildSingleLabelResults(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (_result?['topPredictions'] != null) ...[
          const SizedBox(height: 20),
          Text(
            "Top 5 Predictions",
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
                        backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
                        color: scheme.primary,
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
      ],
    );
  }

  Widget _buildMultiLabelResults(ColorScheme scheme) {
    final rawDetectedClasses = _result?['detectedClasses'] as List? ?? [];
    final segmentPredictions = _result?['segmentPredictions'] as List? ?? [];
    final isMultilabel = _result?['isMultilabel'] == true;
    final summary = _result?['summary'] ?? '';
    final durationSeconds = _result?['durationSeconds'] ?? 0;
    final totalSegments = _result?['totalSegments'] ?? 0;

    // Filter classes with confidence >= 85% (0.85)
    final detectedClasses = rawDetectedClasses.where((cls) {
      final confidence = (cls['maxConfidence'] ?? 0).toDouble();
      return confidence >= 0.85;
    }).toList();

    // Debug: Print detected classes to console
    print('=== MULTI-LABEL DEBUG ===');
    print('Raw detectedClasses count: ${rawDetectedClasses.length}');
    print('Filtered (>=85%) count: ${detectedClasses.length}');
    print('Raw detectedClasses: $rawDetectedClasses');
    print('Filtered detectedClasses: $detectedClasses');
    print('segmentPredictions count: ${segmentPredictions.length}');
    print('=========================');

    // Color palette for detected classes
    final colors = [
      scheme.primary,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary badge
        if (isMultilabel)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.2),
                  scheme.secondary.withValues(alpha: 0.2)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _buildResultRow(
            "Primary Scene",
            _result?['predictedClass']?.toString().toUpperCase() ?? 'N/A',
            scheme,
            isHighlighted: true,
          ),

        const SizedBox(height: 16),

        // Video info
        Row(
          children: [
            _buildInfoChip(scheme, Icons.timer_outlined, "${durationSeconds}s"),
            const SizedBox(width: 8),
            _buildInfoChip(scheme, Icons.grid_view, "$totalSegments segments"),
            const SizedBox(width: 8),
            _buildInfoChip(
                scheme, Icons.layers, "${detectedClasses.length} scenes"),
          ],
        ),

        const SizedBox(height: 20),

        // Detected scenes header
        Text(
          "Detected Scenes",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Responsive grid of detected class tiles
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine number of columns based on available width
            final tileMinWidth = 180.0;
            final crossAxisCount =
                (constraints.maxWidth / tileMinWidth).floor().clamp(1, 3);

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: detectedClasses.asMap().entries.map((entry) {
                final index = entry.key;
                final cls = entry.value;
                final color = colors[index % colors.length];

                return _buildDetectedClassTile(
                  scheme: scheme,
                  cls: cls,
                  color: color,
                  width: crossAxisCount == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - (crossAxisCount - 1) * 10) /
                          crossAxisCount,
                );
              }).toList(),
            );
          },
        ),

        // Timeline visualization
        if (segmentPredictions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            "Timeline",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimeline(scheme, segmentPredictions),
        ],
      ],
    );
  }

  Widget _buildDetectedClassTile({
    required ColorScheme scheme,
    required Map<String, dynamic> cls,
    required Color color,
    required double width,
  }) {
    final className = cls['class'] ?? 'Unknown';
    final confidence = ((cls['maxConfidence'] ?? 0) * 100);
    final percentage = cls['percentageOfVideo'] ?? 0;
    final occurrences = cls['occurrences'] ?? 0;
    final firstDetectedAt = cls['firstDetectedAt'] ?? 0.0;

    // Format timestamp
    String formatTimestamp(double seconds) {
      final mins = (seconds / 60).floor();
      final secs = (seconds % 60).floor();
      return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    }

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with class name and confidence badge
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  className.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          // Confidence percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Confidence",
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${confidence.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // First detected timestamp
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 12, color: scheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                "First at ${formatTimestamp(firstDetectedAt.toDouble())}",
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Occurrences and percentage
          Row(
            children: [
              Icon(Icons.repeat,
                  size: 12, color: scheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "$occurrences segments · ${percentage.toStringAsFixed(0)}% of video",
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ColorScheme scheme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ColorScheme scheme, List segmentPredictions) {
    // Get unique classes for color mapping
    final uniqueClasses = segmentPredictions
        .map((s) => s['predictedClass'] as String)
        .toSet()
        .toList();

    final colors = [
      scheme.primary,
      scheme.secondary,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return Column(
      children: [
        // Timeline bar
        SizedBox(
          height: 24,
          child: Row(
            children: segmentPredictions.map((segment) {
              final classIndex =
                  uniqueClasses.indexOf(segment['predictedClass']);
              final color = colors[classIndex % colors.length];
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: uniqueClasses.asMap().entries.map((entry) {
            final color = colors[entry.key % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
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
                  ? scheme.primary.withValues(alpha: 0.2)
                  : scheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isHighlighted ? 12 : 8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isHighlighted ? scheme.primary : scheme.onSurface,
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
