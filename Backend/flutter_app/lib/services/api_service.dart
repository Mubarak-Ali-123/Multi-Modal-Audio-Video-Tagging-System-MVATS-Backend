import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// API Service for communicating with MVATS Backend
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  /// Check backend health status
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.apiHealth),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Upload media files with better error handling
  Future<Map<String, dynamic>> uploadMedia(
    String filePath,
    String fileType,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.mediaUpload),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      request.fields['fileType'] = fileType;

      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Upload failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all media with error handling
  Future<List<dynamic>> getAllMedia() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.mediaGetAll),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw ApiException(
          'Failed to fetch media: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get specific media by ID
  Future<Map<String, dynamic>> getMediaById(String mediaId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.mediaGetById(mediaId)),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to fetch media: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save audio history with error handling
  Future<bool> saveAudioHistory(Map<String, dynamic> historyData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.historyAudio),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(historyData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw ApiException(
          'Failed to save audio history: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save video history with error handling
  Future<bool> saveVideoHistory(Map<String, dynamic> historyData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.historyVideo),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(historyData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw ApiException(
          'Failed to save video history: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save fusion history with error handling
  Future<bool> saveFusionHistory(Map<String, dynamic> historyData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.historyFusion),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(historyData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw ApiException(
          'Failed to save fusion history: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all history
  Future<Map<String, dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.historyAggregate),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to fetch history: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create tags with error handling
  Future<Map<String, dynamic>> createTag(
    String tagName,
    String fileType,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.tagsCreate),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tagName': tagName,
          'fileType': fileType,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to create tag: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all tags with error handling
  Future<List<dynamic>> getTags() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.tagsList),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw ApiException(
          'Failed to fetch tags: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
