/// API Configuration for MVATS Backend
class ApiConfig {
  /// Backend server base URL
  /// Change this to your actual backend server address
  static const String baseUrl = 'http://localhost:3000';

  /// API endpoints
  static const String apiHealth = '$baseUrl/health';
  static const String apiInfo = '$baseUrl/api';

  /// Media endpoints
  static const String mediaUpload = '$baseUrl/media/upload';
  static const String mediaGetAll = '$baseUrl/media';
  static String mediaGetById(String mediaId) => '$baseUrl/media/$mediaId';

  /// Tags endpoints
  static const String tagsCreate = '$baseUrl/tags';
  static const String tagsList = '$baseUrl/tags';

  /// History endpoints
  static const String historyAudio = '$baseUrl/history/audio';
  static const String historyVideo = '$baseUrl/history/video';
  static const String historyFusion = '$baseUrl/history/fusion';
  static const String historyAggregate = '$baseUrl/history';

  /// Uploads directory
  static const String uploadsDirectory = '$baseUrl/uploads';
  static String getFileUrl(String fileName) => '$uploadsDirectory/$fileName';
}
