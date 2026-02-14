import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for video classification using the MVATS backend pipeline.
///
/// Flow: Flutter → Node.js backend (port 3000) → Flask ML server (port 5000)
///
/// The backend handles:
/// 1. Saving the video to storage
/// 2. Saving video metadata in MongoDB
/// 3. Sending the video to the ML inference server
/// 4. Saving generated tags in MongoDB
/// 5. Returning full results to this service
class VideoClassifierService {
  static const List<String> classNames = [
    'airport',
    'bus',
    'metro(underground)',
    'metro_station(underground)',
    'park',
    'public_square',
    'shopping_mall',
    'street_pedestrian',
    'street_traffic',
    'tram'
  ];

  // Node.js backend URL — this is the single entry point
  String _backendUrl = 'http://localhost:3000';

  void setApiUrl(String url) {
    _backendUrl = url;
  }

  /// Upload video → backend saves it → runs ML model → saves tags → returns result
  Future<Map<String, dynamic>> classifyVideo(String videoPath,
      {bool multiLabel = false}) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception('Video file not found: $videoPath');
      }

      // POST to backend /video/upload — the backend handles the full pipeline
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/video/upload'),
      );

      request.files.add(await http.MultipartFile.fromPath('video', videoPath));

      if (multiLabel) {
        request.fields['multi_label'] = 'true';
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body);
        // The backend returns { success, video, inference, tags }
        // Extract the inference result which has the format the UI expects
        final inference = body['inference'] ?? {};
        return inference;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock result for demo purposes when backend is not available
      return multiLabel
          ? _getMockMultiLabelPrediction()
          : _getMockPrediction('video');
    }
  }

  /// Classify a video file with multi-label scene detection
  Future<Map<String, dynamic>> classifyVideoMultiLabel(String videoPath) async {
    return classifyVideo(videoPath, multiLabel: true);
  }

  /// Get tags for a previously classified video
  Future<List<Map<String, dynamic>>> getTagsForVideo(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/video/$videoId/tags'),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return List<Map<String, dynamic>>.from(body['tags'] ?? []);
      } else {
        throw Exception('Failed to fetch tags');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get all previously classified videos
  Future<List<Map<String, dynamic>>> getAllVideos() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/video/'),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return List<Map<String, dynamic>>.from(body['videos'] ?? []);
      } else {
        throw Exception('Failed to fetch videos');
      }
    } catch (e) {
      return [];
    }
  }

  /// Classify an audio file
  Future<Map<String, dynamic>> classifyAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/predict/audio'),
      );

      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return _getMockPrediction('audio');
    }
  }

  /// Classify using both audio and video (multimodal)
  Future<Map<String, dynamic>> classifyMultimodal({
    String? videoPath,
    String? audioPath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/predict/multimodal'),
      );

      if (videoPath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('video', videoPath));
      }
      if (audioPath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('audio', audioPath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return _getMockPrediction('multimodal');
    }
  }

  /// Mock prediction for demo when backend is unavailable
  Map<String, dynamic> _getMockPrediction(String type) {
    return {
      'predictedClass': 'street_traffic',
      'confidence': 0.87,
      'topPredictions': [
        {'class': 'street_traffic', 'confidence': 0.87},
        {'class': 'street_pedestrian', 'confidence': 0.08},
        {'class': 'bus', 'confidence': 0.03},
        {'class': 'park', 'confidence': 0.01},
        {'class': 'public_square', 'confidence': 0.01},
      ],
      'type': type,
      'isDemo': true,
      'message': 'Demo result - Backend server not connected. '
          'Run the Python inference server for real predictions.',
    };
  }

  /// Mock multi-label prediction for demo
  Map<String, dynamic> _getMockMultiLabelPrediction() {
    return {
      'type': 'video_multilabel',
      'isMultilabel': true,
      'durationSeconds': 30.0,
      'totalSegments': 6,
      'segmentDuration': 5,
      'predictedClass': 'bus',
      'confidence': 0.98,
      'detectedClasses': [
        {
          'class': 'bus',
          'maxConfidence': 0.98,
          'occurrences': 3,
          'percentageOfVideo': 50.0,
          'firstDetectedAt': 0.0,
          'lastDetectedAt': 15.0,
        },
        {
          'class': 'tram',
          'maxConfidence': 0.92,
          'occurrences': 2,
          'percentageOfVideo': 33.3,
          'firstDetectedAt': 5.0,
          'lastDetectedAt': 12.5,
        },
        {
          'class': 'street_traffic',
          'maxConfidence': 0.87,
          'occurrences': 1,
          'percentageOfVideo': 16.7,
          'firstDetectedAt': 12.5,
          'lastDetectedAt': 17.5,
        },
      ],
      'secondaryClasses': [
        {'class': 'tram', 'maxConfidence': 0.92},
        {'class': 'street_traffic', 'maxConfidence': 0.87},
      ],
      'topPredictions': [
        {'class': 'bus', 'confidence': 0.98},
        {'class': 'tram', 'confidence': 0.92},
        {'class': 'street_traffic', 'confidence': 0.87},
      ],
      'segmentPredictions': [
        {
          'segment': 0,
          'startTime': 0.0,
          'endTime': 5.0,
          'predictedClass': 'bus',
          'confidence': 0.98
        },
        {
          'segment': 1,
          'startTime': 2.5,
          'endTime': 7.5,
          'predictedClass': 'bus',
          'confidence': 0.95
        },
        {
          'segment': 2,
          'startTime': 5.0,
          'endTime': 10.0,
          'predictedClass': 'tram',
          'confidence': 0.92
        },
        {
          'segment': 3,
          'startTime': 7.5,
          'endTime': 12.5,
          'predictedClass': 'tram',
          'confidence': 0.88
        },
        {
          'segment': 4,
          'startTime': 10.0,
          'endTime': 15.0,
          'predictedClass': 'bus',
          'confidence': 0.91
        },
        {
          'segment': 5,
          'startTime': 12.5,
          'endTime': 17.5,
          'predictedClass': 'street_traffic',
          'confidence': 0.87
        },
      ],
      'summary': 'Detected 3 scene(s): bus, tram, street_traffic',
      'isDemo': true,
      'message': 'Demo result - Backend server not connected.',
    };
  }
}
