# MVATS Backend

**Multi-Video & Audio Tagging System** - Backend API built with Node.js, Express, and MongoDB.

## Features

- Express.js framework with ES6 modules
- MongoDB with Mongoose ODM
- RESTful API structure
- Input validation with express-validator
- Error handling middleware
- Security headers (Helmet)
- CORS enabled
- Request logging (Morgan)
- Auto-timestamps for all collections

## Project Structure

```
.
├── server.js                    # Main server entry point
├── package.json                 # Dependencies and scripts
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore file
├── flutter_app/                # Flutter mobile app (UI client)
│   ├── lib/                    # Dart source code
│   ├── pubspec.yaml           # Flutter dependencies
│   ├── android/               # Android build files
│   └── ios/                   # iOS build files
├── config/                     # Configuration files
│   └── database.js            # MongoDB connection
├── controllers/                # Request handlers (business logic)
│   ├── tagController.js
│   ├── mediaController.js
│   ├── audioHistoryController.js
│   ├── videoHistoryController.js
│   └── fusionHistoryController.js
├── middleware/                 # Custom middleware
│   ├── auth.js                # Authentication middleware
│   └── errorHandler.js        # Error handling middleware
├── models/                     # MongoDB models (Mongoose schemas)
│   ├── Media.js               # media collection
│   ├── Tag.js                 # tag collection
│   ├── AudioHistory.js        # audio_history collection
│   ├── VideoHistory.js        # video_history collection
│   └── FusionHistory.js       # fusion_history collection
├── routes/                     # API routes
│   ├── tags.js
│   ├── media.js
│   ├── audioHistory.js
│   ├── videoHistory.js
│   └── fusionHistory.js
└── utils/                      # Utility functions
    ├── logger.js
    └── validation.js
```

## Database Schema

### Collections

1. **media**
   - `mediaId` (String, unique) – shared identifier across collections
   - `fileName` (String, optional)
   - `fileUrl` (String, optional)
   - `mediaType` (String: "audio", "video", "fusion")
   - `enteredAt` (Date)

2. **tags**
   - `tagId` (String, unique)
   - `tagName` (String)
   - `fileType` (String: "audio", "video", "fusion")
   - `mediaId` (String, references media.mediaId)
   - `media` (ObjectId, references media document)

3. **audio_history**
   - `mediaId` (String)
   - `media` (ObjectId → media)
   - `tagId` (String → tags)
   - `tag` (ObjectId → tags)
   - `confidenceScore` (Number, 0-1)

4. **video_history**
   - Same structure as audio_history (confidenceScore)

5. **fusion_history**
   - Same structure as audio_history but uses `fusionConfidence`

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file based on `.env.example`:
```bash
# On Windows PowerShell
Copy-Item .env.example .env

# On Linux/Mac
cp .env.example .env
```

3. Update the `.env` file with your MongoDB connection string:
```
MONGODB_URI=mongodb://localhost:27017/mvats
```

## Running the Server

### Development mode (with auto-reload):
```bash
npm run dev
```

### Production mode:
```bash
npm start
```

The server will start on `http://localhost:3000` (or the port specified in your `.env` file).

## API Endpoints

### Health Check
- `GET /` - Welcome message with API information
- `GET /health` - Check server status

### Tags
- `GET /tags` - List tags (`?mediaId=` / `?fileType=`)
- `GET /tags/:tagId` - Get tag by tagId or document id
- `POST /tags` - Create a tag (requires `mediaId`, `tagName`, `fileType`)

### Media
- `GET /media` - Get media (optional `?mediaType=`)
- `GET /media/:mediaId` - Get media by `mediaId`
- `POST /media/upload` - Upload metadata or local file

### Audio History
- `GET /history/audio?mediaId=` - List audio predictions for a mediaId
- `POST /history/audio` - Log an audio prediction (`mediaId`, `tagId`, `confidenceScore`)

### Video History
- `GET /history/video?mediaId=` - List video predictions
- `POST /history/video` - Log video prediction

### Fusion History
- `GET /history/fusion?mediaId=` - List fusion predictions
- `POST /history/fusion` - Log fusion prediction (`fusionConfidence`)

### Aggregated History
- `GET /history` - Combined audio/video/fusion entries (`?type=` to filter)
- `GET /history/:mediaId` - Combined entries for a specific media

## Example API Usage

### Create a media entry:
```bash
POST /media/upload
Content-Type: application/json

{
  "fileName": "sample_audio.mp3",
  "mediaType": "audio",
  "fileUrl": "https://example.com/sample.mp3"
}
```

### Create a tag:
```bash
POST /tags
Content-Type: application/json

{
  "mediaId": "media_ABC123",
  "tagName": "car_horn",
  "fileType": "audio"
}
```

### Log an audio prediction:
```bash
POST /history/audio
Content-Type: application/json

{
  "mediaId": "media_ABC123",
  "tagId": "tag_DEF456",
  "confidenceScore": 0.92
}
```

## Validation

All endpoints include input validation:
- Media type must be "audio", "video", or "fusion"
- Tags must reference an existing media entry
- History endpoints require valid `mediaId`, `tagId`, and confidence scores between 0 and 1

## License

ISC
