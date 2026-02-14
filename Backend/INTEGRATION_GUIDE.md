# MVATS - Backend & Flutter Integration

## Overview

MVATS (Multi-Video & Audio Tagging System) consists of:
- **Backend**: Node.js Express API with MongoDB
- **Frontend**: Flutter mobile application

## Backend Setup

### Prerequisites
- Node.js v14+
- MongoDB Atlas account or local MongoDB instance
- npm or yarn

### Installation

```bash
cd Backend
npm install
```

### Environment Configuration

Create `.env` file with:
```
PORT=3000
HOST=localhost
NODE_ENV=development
MONGODB_URI=your_mongodb_connection_string
```

### Running Backend

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The API will be available at `http://localhost:3000`

### API Endpoints

#### Health Check
- `GET /health` - Server health status

#### Media Management
- `POST /media/upload` - Upload audio/video file
- `GET /media` - Get all media
- `GET /media/:mediaId` - Get specific media

#### Tags
- `POST /tags` - Create tag
- `GET /tags` - List all tags

#### History
- `POST /history/audio` - Save audio classification history
- `POST /history/video` - Save video classification history
- `POST /history/fusion` - Save fusion classification history
- `GET /history` - Get all history

## Flutter App Setup

### Prerequisites
- Flutter v3.6.1+
- Dart SDK
- iOS/Android development environment

### Installation

```bash
cd Backend/flutter_app
flutter pub get
```

### Configuration

The Flutter app uses `lib/config/api_config.dart` to connect to the backend.

**Default configuration**:
```dart
static const String baseUrl = 'http://localhost:3000';
```

**For deployment**:
- Update `baseUrl` to your production backend URL
- Update `lib/services/api_service.dart` with production endpoints if needed

### Running the App

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

#### Web
```bash
flutter run -w
```

### Building for Release

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Integration Points

### API Service
The Flutter app uses `lib/services/api_service.dart` singleton class for all backend communication:

```dart
final ApiService apiService = ApiService();

// Upload media
await apiService.uploadMedia(filePath, 'audio');

// Get history
await apiService.getHistory();

// Save classification result
await apiService.saveAudioHistory(historyData);
```

### API Configuration
Centralized configuration in `lib/config/api_config.dart`:

```dart
ApiConfig.mediaUpload    // POST endpoint for uploads
ApiConfig.historyAudio   // POST endpoint for audio history
ApiConfig.historyVideo   // POST endpoint for video history
ApiConfig.historyFusion  // POST endpoint for fusion history
```

## Development Workflow

1. Start backend server:
   ```bash
   cd Backend
   npm run dev
   ```

2. Run Flutter app:
   ```bash
   cd Backend/flutter_app
   flutter run
   ```

3. Backend API runs on `http://localhost:3000`
4. Flutter app communicates with backend via HTTP

## Network Configuration

### Local Development
- Backend: `http://localhost:3000`
- Android emulator can access host machine via `http://10.0.2.2:3000`
- iOS simulator can access host machine via `http://localhost:3000`

### Production Deployment
- Update `lib/config/api_config.dart` baseUrl
- Ensure CORS is properly configured in `server.js`
- Use HTTPS for secure communication

## Troubleshooting

### Backend Connection Issues
1. Verify backend is running: `curl http://localhost:3000/health`
2. Check firewall settings
3. Update API baseUrl in Flutter config

### Upload Failures
1. Check `uploads/` directory permissions
2. Verify file size limits in `server.js`
3. Check MongoDB connection

### CORS Errors
1. Ensure CORS is enabled in `server.js`
2. Check allowed origins
3. Verify Content-Type headers

## Project Structure

```
Backend/
├── server.js              # Main entry point
├── package.json           # Node dependencies
├── .env                   # Environment variables
├── config/               # Configuration
├── controllers/          # Business logic
├── models/              # MongoDB schemas
├── routes/              # API routes
├── utils/               # Utilities
├── middleware/          # Express middleware
├── uploads/             # Uploaded files
└── flutter_app/         # Flutter mobile UI
    ├── lib/
    │   ├── config/      # API configuration
    │   ├── services/    # API service
    │   ├── screens/     # UI screens
    │   ├── themes/      # Theme settings
    │   └── widgets/     # Reusable widgets
    ├── pubspec.yaml     # Flutter dependencies
    └── ...
```

## Contributing

1. Create feature branches from `main`
2. Follow REST API conventions
3. Update tests and documentation
4. Create pull requests for review

## License

ISC

## Support

For issues or questions, please contact the development team.
