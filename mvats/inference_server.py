"""
MVATS Video Classification API Server
=====================================

This Flask server provides REST API endpoints for the MVATS video classification model.
Place this file alongside your model file and run it to enable Flutter app inference.

Requirements:
    pip install flask flask-cors torch torchvision opencv-python numpy

Usage:
    python inference_server.py

The server will start on http://localhost:5000

Model file should be at: assets/models/best_model_94pct.pth
Or update MODEL_PATH below to your model location.
"""

import os
import torch
import torch.nn as nn
import torchvision.models.video as video_models
import numpy as np
import cv2
from flask import Flask, request, jsonify
from flask_cors import CORS
import tempfile

app = Flask(__name__)
CORS(app)

# ============================================================================
# CONFIGURATION - UPDATE THIS PATH TO YOUR MODEL LOCATION
# ============================================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(SCRIPT_DIR, "assets", "models", "best_model_94pct.pth")

# ============================================================================
# MODEL DEFINITION
# ============================================================================

class VideoClassifier(nn.Module):
    def __init__(self, num_classes=10, model_type='r2plus1d_18', dropout=0.5):
        super(VideoClassifier, self).__init__()
        
        if model_type == 'r2plus1d_18':
            self.base = video_models.r2plus1d_18(pretrained=False)
        
        num_features = self.base.fc.in_features
        self.base.fc = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(num_features, num_classes)
        )
    
    def forward(self, x):
        return self.base(x)

# Class names
CLASS_NAMES = [
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
]

# Global model variable
model = None
device = None

def load_model():
    """Load the video classification model"""
    global model, device
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    model = VideoClassifier(
        num_classes=10,
        model_type='r2plus1d_18',
        dropout=0.5
    )
    
    if os.path.exists(MODEL_PATH):
        checkpoint = torch.load(MODEL_PATH, map_location=device, weights_only=False)
        
        # Handle different checkpoint formats
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'])
        else:
            model.load_state_dict(checkpoint)
        
        print(f"Model loaded from {MODEL_PATH}")
    else:
        print(f"WARNING: Model file not found at {MODEL_PATH}")
        print("Using randomly initialized model for demo purposes.")
    
    model.to(device)
    model.eval()
    return model

def extract_frames_from_video(video_path, num_frames=16):
    """Extract frames from video file"""
    cap = cv2.VideoCapture(video_path)
    
    if not cap.isOpened():
        raise ValueError(f"Cannot open video: {video_path}")
    
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    frame_indices = np.linspace(0, max(0, total_frames - 1), num_frames).astype(int)
    
    frames = []
    for idx in frame_indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ret, frame = cap.read()
        
        if ret:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            rgb = cv2.resize(rgb, (224, 224))
            frames.append(rgb)
        else:
            if len(frames) > 0:
                frames.append(frames[-1].copy())
    
    cap.release()
    
    # Pad if needed
    while len(frames) < num_frames:
        frames.append(frames[-1].copy() if frames else np.zeros((224, 224, 3), dtype=np.uint8))
    
    return np.array(frames[:num_frames])

def predict_video(video_path, multi_label=False):
   
    global model, device
    
    if multi_label:
        return predict_video_multilabel(video_path)
    
    # Extract frames
    frames = extract_frames_from_video(video_path)
    
    # Convert to tensor: normalize and reshape
    frames = frames.astype(np.float32) / 255.0
    frames = torch.from_numpy(frames).permute(3, 0, 1, 2).float()  # (C, T, H, W)
    frames = frames.unsqueeze(0).to(device)  # (1, C, T, H, W)
    
    # Predict
    with torch.no_grad():
        outputs = model(frames)
        probs = torch.softmax(outputs, dim=1)
        confidence, pred_idx = probs.max(1)
    
    predicted_class = CLASS_NAMES[pred_idx.item()]
    confidence_value = confidence.item()
    
    # Get top-5 predictions
    top_probs, top_indices = torch.topk(probs, 5)
    top_predictions = [
        {
            'class': CLASS_NAMES[idx.item()],
            'confidence': prob.item()
        }
        for prob, idx in zip(top_probs[0], top_indices[0])
    ]
    
    return {
        'predictedClass': predicted_class,
        'confidence': confidence_value,
        'topPredictions': top_predictions,
        'type': 'video'
    }


def predict_video_multilabel(video_path, segment_duration_sec=None, min_confidence=0.85):
  
    global model, device
    
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError(f"Cannot open video: {video_path}")
    
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration_sec = total_frames / fps if fps > 0 else 0
    
    # Auto-calculate segment duration based on video length
    if segment_duration_sec is None:
        if duration_sec <= 2:
            segment_duration_sec = 0.5  # Very short videos: 0.5s segments
        elif duration_sec <= 5:
            segment_duration_sec = 1.0  # Short videos: 1s segments
        elif duration_sec <= 30:
            segment_duration_sec = 2.0  # Medium videos: 2s segments
        else:
            segment_duration_sec = 3.0  # Long videos: 3s segments
    
    # Calculate segment parameters - use smaller segments with less overlap for distinct scene capture
    frames_per_segment = max(8, int(segment_duration_sec * fps)) if fps > 0 else 16
    overlap_ratio = 0.0  # No overlap for short videos to get distinct segments
    step_frames = max(1, int(frames_per_segment * (1 - overlap_ratio)))
    
    segment_results = []
    detected_classes = {}  # Track all detected classes with max confidence
    class_occurrences = {}  # Track how many segments each class appears in
    class_first_detected = {}  # Track first detection time for each class
    class_last_detected = {}  # Track last detection time for each class
    all_segment_classes = {}  # Track ALL classes that appear in top predictions
    
    start_frame = 0
    segment_idx = 0
    
    print(f"Analyzing video: {duration_sec:.1f}s, {total_frames} frames, {fps:.1f} fps")
    print(f"Segment size: {segment_duration_sec}s ({frames_per_segment} frames), step: {step_frames} frames")
    
    while start_frame < total_frames:
        end_frame = min(start_frame + frames_per_segment, total_frames)
        
        # Need at least some frames to analyze
        if end_frame - start_frame < 8:
            break
        
        # Extract 16 frames evenly distributed within this segment
        frame_indices = np.linspace(start_frame, end_frame - 1, 16).astype(int)
        
        frames = []
        for idx in frame_indices:
            cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
            ret, frame = cap.read()
            if ret:
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                rgb = cv2.resize(rgb, (224, 224))
                frames.append(rgb)
            elif len(frames) > 0:
                frames.append(frames[-1].copy())
        
        # Pad if needed
        while len(frames) < 16:
            if frames:
                frames.append(frames[-1].copy())
            else:
                frames.append(np.zeros((224, 224, 3), dtype=np.uint8))
        
        # Convert to tensor and predict
        frames_array = np.array(frames[:16]).astype(np.float32) / 255.0
        tensor = torch.from_numpy(frames_array).permute(3, 0, 1, 2).float()
        tensor = tensor.unsqueeze(0).to(device)
        
        with torch.no_grad():
            outputs = model(tensor)
            probs = torch.softmax(outputs, dim=1)
            confidence, pred_idx = probs.max(1)
        
        predicted_class = CLASS_NAMES[pred_idx.item()]
        conf_value = confidence.item()
        
        # Get top 3 for this segment
        top_probs, top_indices = torch.topk(probs, 3)
        top_3 = [
            {'class': CLASS_NAMES[i.item()], 'confidence': round(p.item(), 4)}
            for p, i in zip(top_probs[0], top_indices[0])
        ]
        
        # Calculate time range for this segment
        start_time = start_frame / fps if fps > 0 else 0
        end_time = end_frame / fps if fps > 0 else 0
        
        segment_results.append({
            'segment': segment_idx,
            'startTime': round(start_time, 2),
            'endTime': round(end_time, 2),
            'predictedClass': predicted_class,
            'confidence': round(conf_value, 4),
            'top3': top_3
        })
        
        # Print per-segment prediction for debugging
        print(f"  Segment {segment_idx}: {start_time:.1f}s - {end_time:.1f}s => {predicted_class} ({conf_value*100:.1f}%)")
        
        # Track detected classes (keep highest confidence for each class)
        # ALWAYS track the top-1 prediction regardless of confidence
        if predicted_class not in detected_classes or conf_value > detected_classes[predicted_class]:
            detected_classes[predicted_class] = conf_value
        
        # Track first and last detection times
        if predicted_class not in class_first_detected:
            class_first_detected[predicted_class] = start_time
        class_last_detected[predicted_class] = end_time
        
        # Track occurrences (count how many segments have this as top prediction)
        class_occurrences[predicted_class] = class_occurrences.get(predicted_class, 0) + 1
        
        # Also track ALL top-3 classes with confidence >= 85%
        for item in top_3:
            cls_name = item['class']
            cls_conf = item['confidence']
            # Track if confidence >= 85% OR if it's the top prediction
            if cls_conf >= 0.85 or cls_name == predicted_class:
                if cls_name not in all_segment_classes or cls_conf > all_segment_classes[cls_name]['confidence']:
                    all_segment_classes[cls_name] = {
                        'confidence': cls_conf,
                        'firstDetectedAt': start_time
                    }
                if cls_name not in class_first_detected:
                    class_first_detected[cls_name] = start_time
                if cls_name not in class_last_detected or end_time > class_last_detected[cls_name]:
                    class_last_detected[cls_name] = end_time
                # Initialize occurrence count if not exists
                if cls_name not in class_occurrences:
                    class_occurrences[cls_name] = 0
        
        start_frame += step_frames
        segment_idx += 1
    
    cap.release()
    
    # Merge detected_classes with all_segment_classes to capture secondary predictions
    for cls_name, info in all_segment_classes.items():
        if cls_name not in detected_classes:
            detected_classes[cls_name] = info['confidence']
    
    # Sort detected classes by confidence
    sorted_classes = sorted(detected_classes.items(), key=lambda x: x[1], reverse=True)
    
    # Filter significant classes (above minimum confidence threshold)
    # Include ALL classes that were a top-1 prediction in any segment
    significant_classes = [(cls, conf) for cls, conf in sorted_classes if conf >= min_confidence]
    
    # Print debug info
    print(f"Total segments analyzed: {len(segment_results)}")
    print(f"All detected classes: {sorted_classes}")
    print(f"Significant classes (>= {min_confidence*100}%): {significant_classes}")
    
    # Build detected classes list - include ALL classes that were top-1 OR have >= 85% confidence
    detected_classes_list = [
        {
            'class': cls,
            'maxConfidence': round(conf, 4),
            'occurrences': class_occurrences.get(cls, 0),
            'percentageOfVideo': round(class_occurrences.get(cls, 0) / max(1, len(segment_results)) * 100, 1),
            'firstDetectedAt': round(class_first_detected.get(cls, 0), 2),
            'lastDetectedAt': round(class_last_detected.get(cls, 0), 2)
        }
        for cls, conf in sorted_classes  # Include ALL detected classes, not filtered
    ]
    
    # Determine primary and secondary classes
    primary_class = sorted_classes[0][0] if sorted_classes else 'unknown'
    primary_confidence = sorted_classes[0][1] if sorted_classes else 0
    
    secondary_classes = [
        {'class': cls, 'maxConfidence': round(conf, 4)}
        for cls, conf in significant_classes[1:4]  # Up to 3 secondary classes
    ]
    
    return {
        'type': 'video_multilabel',
        'isMultilabel': len(significant_classes) > 1,
        'durationSeconds': round(duration_sec, 2),
        'totalSegments': len(segment_results),
        'segmentDuration': segment_duration_sec,
        'predictedClass': primary_class,  # For backward compatibility
        'confidence': round(primary_confidence, 4),  # For backward compatibility
        'detectedClasses': detected_classes_list,
        'secondaryClasses': secondary_classes,
        'topPredictions': [  # For backward compatibility
            {'class': cls, 'confidence': round(conf, 4)}
            for cls, conf in sorted_classes[:5]
        ],
        'segmentPredictions': segment_results,
        'summary': f"Detected {len(significant_classes)} scene(s): {', '.join([c[0] for c in significant_classes])}"
    }


# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'device': str(device)
    })

@app.route('/predict/video', methods=['POST'])
def predict_video_endpoint():
    """Predict class from uploaded video file
    
    Query params:
        multi_label: Set to 'true' to enable multi-label scene detection
        segment_duration: Duration of each segment in seconds (default: 5)
    """
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided'}), 400
    
    video_file = request.files['video']
    
    # Check for multi-label mode
    multi_label = request.form.get('multi_label', 'false').lower() == 'true'
    
    # Save to temporary file
    with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tmp:
        video_file.save(tmp.name)
        tmp_path = tmp.name
    
    try:
        result = predict_video(tmp_path, multi_label=multi_label)
        return jsonify(result)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500
    finally:
        # Clean up temp file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

@app.route('/predict/audio', methods=['POST'])
def predict_audio_endpoint():
    """Predict class from uploaded audio file"""
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400
    
    # TODO: Implement audio model inference
    # For now, return a placeholder response
    return jsonify({
        'predictedClass': 'street_traffic',
        'confidence': 0.85,
        'topPredictions': [
            {'class': 'street_traffic', 'confidence': 0.85},
            {'class': 'bus', 'confidence': 0.10},
            {'class': 'park', 'confidence': 0.05},
        ],
        'type': 'audio',
        'message': 'Audio model inference - implement your audio model here'
    })

@app.route('/predict/multimodal', methods=['POST'])
def predict_multimodal_endpoint():
    """Predict class from both video and audio"""
    video_result = None
    audio_result = None
    
    if 'video' in request.files:
        video_file = request.files['video']
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tmp:
            video_file.save(tmp.name)
            try:
                video_result = predict_video(tmp.name)
            finally:
                if os.path.exists(tmp.name):
                    os.remove(tmp.name)
    
    # TODO: Implement multimodal fusion
    # For now, return video result or combined placeholder
    if video_result:
        video_result['type'] = 'multimodal'
        return jsonify(video_result)
    
    return jsonify({
        'predictedClass': 'street_traffic',
        'confidence': 0.90,
        'topPredictions': [
            {'class': 'street_traffic', 'confidence': 0.90},
        ],
        'type': 'multimodal',
        'message': 'Multimodal fusion - implement fusion logic here'
    })

@app.route('/classes', methods=['GET'])
def get_classes():
    """Get list of class names"""
    return jsonify({'classes': CLASS_NAMES})

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    print("Loading MVATS Video Classification Model...")
    load_model()
    print(f"\nStarting server on http://localhost:5000")
    print("Available endpoints:")
    print("  GET  /health          - Health check")
    print("  GET  /classes         - Get class names")
    print("  POST /predict/video   - Classify video file")
    print("  POST /predict/audio   - Classify audio file")
    print("  POST /predict/multimodal - Classify multimodal input")
    app.run(host='0.0.0.0', port=5000, debug=False)
