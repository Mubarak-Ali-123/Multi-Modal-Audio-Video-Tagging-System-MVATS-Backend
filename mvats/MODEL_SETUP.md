# MVATS Model Setup Guide

This guide explains how to set up the video classification model for the MVATS Flutter application.

## Model File Location

The trained model file `best_model_94pct.pth` should be placed at:
```
C:\Users\ASUS\OneDrive - Higher Education Commission\Desktop\best_model_94pct.pth
```

Or update the path in `inference_server.py`:
```python
MODEL_PATH = r"C:\Users\ASUS\OneDrive - Higher Education Commission\Desktop\best_model_94pct.pth"
```

## Setting Up the Backend Server

The Flutter app communicates with a Python backend server for model inference.

### 1. Install Python Dependencies

```bash
pip install flask flask-cors torch torchvision opencv-python numpy
```

### 2. Run the Inference Server

Navigate to the mvats project folder and run:

```bash
cd "c:\Users\ASUS\OneDrive - Higher Education Commission\Desktop\Flutter_app\mvats"
python inference_server.py
```

The server will start on `http://localhost:5000`

### 3. Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/classes` | GET | Get list of class names |
| `/predict/video` | POST | Classify video file |
| `/predict/audio` | POST | Classify audio file |
| `/predict/multimodal` | POST | Classify multimodal input |

## Class Labels

The model classifies videos into 10 acoustic scene categories:

1. `airport`
2. `bus`
3. `metro(underground)`
4. `metro_station(underground)`
5. `park`
6. `public_square`
7. `shopping_mall`
8. `street_pedestrian`
9. `street_traffic`
10. `tram`

## Demo Mode

If the backend server is not running, the Flutter app will display demo results. This is useful for testing the UI without the model.

## Model Architecture

The video classifier uses a **R(2+1)D-18** architecture:
- Pre-trained on Kinetics-400
- Fine-tuned for acoustic scene classification
- Input: 16 frames at 224x224 resolution
- Output: 10-class probability distribution

## Flutter App Integration

The Flutter app communicates with the backend through the `VideoClassifierService` class in:
```
lib/services/video_classifier_service.dart
```

To change the backend URL:
```dart
final classifier = VideoClassifierService();
classifier.setApiUrl('http://your-server-ip:5000');
```

## Drag & Drop Support

The testing screens support:
- **Drag & Drop**: Drop files directly onto the upload area
- **File Browser**: Click "Browse Files" to select files

### Supported Formats

| Mode | Formats |
|------|---------|
| Video | MP4, AVI, MOV, MKV |
| Audio | MP3, WAV, AAC, FLAC, OGG |
| Multimodal | Any combination above |

## Troubleshooting

### "Demo" Badge Appears
The backend server is not connected. Make sure:
1. The server is running (`python inference_server.py`)
2. The server is accessible at `http://localhost:5000`

### Model Not Found Error
Update `MODEL_PATH` in `inference_server.py` to point to your model file.

### CUDA Not Available
The model will run on CPU if CUDA is not available. This is slower but functional.
