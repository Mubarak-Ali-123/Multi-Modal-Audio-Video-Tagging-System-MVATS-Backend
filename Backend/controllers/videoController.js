import fs from 'fs';
import path from 'path';
import Video from '../models/Video.js';
import VideoTag from '../models/VideoTag.js';

const INFERENCE_URL = process.env.INFERENCE_URL || 'http://localhost:5000';

/**
 * Upload video → save to storage → save metadata → run model → save tags → return result
 * This is the single endpoint that handles the full pipeline.
 */
export const uploadAndClassify = async (req, res) => {
  const file = req.file;
  if (!file) {
    return res.status(400).json({ success: false, error: 'No video file uploaded.' });
  }

  const multiLabel = req.body.multi_label === 'true';
  const userId = req.body.user_id || 'anonymous';
  const videoId = `vid_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Step 1 & 2: File is already saved to storage by multer
  // Step 3: Save video metadata in DB
  let video;
  try {
    video = await Video.create({
      video_id: videoId,
      user_id: userId,
      video_name: file.originalname,
      video_path: file.path,
      status: 'uploaded',
      upload_time: new Date()
    });
  } catch (err) {
    // Clean up uploaded file on DB error
    fs.unlink(file.path, () => {});
    return res.status(500).json({ success: false, error: 'Failed to save video metadata.', details: err.message });
  }

  // Step 4: Run ML model on the saved video
  video.status = 'processing';
  await video.save();

  let inferenceResult;
  try {
    const formData = new FormData();
    const fileBuffer = fs.readFileSync(video.video_path);
    const blob = new Blob([fileBuffer]);
    formData.append('video', blob, video.video_name);
    if (multiLabel) {
      formData.append('multi_label', 'true');
    }

    const response = await fetch(`${INFERENCE_URL}/predict/video`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Inference server responded with ${response.status}: ${response.statusText}`);
    }

    inferenceResult = await response.json();
  } catch (err) {
    video.status = 'failed';
    await video.save();
    return res.status(502).json({
      success: false,
      error: 'Inference server error. Is the Python ML server running on port 5000?',
      details: err.message,
      video: { video_id: video.video_id, video_name: video.video_name, status: video.status }
    });
  }

  // Step 5: Save generated tags in DB linked to the video
  const topPredictions = inferenceResult.topPredictions || [];
  const savedTags = [];
  try {
    for (const pred of topPredictions) {
      const tag = await VideoTag.create({
        tag_id: `${videoId}_${pred.class}_${Date.now()}`,
        video_id: videoId,
        video: video._id,
        tag_name: pred.class,
        confidence_score: pred.confidence,
        created_at: new Date()
      });
      savedTags.push(tag);
    }

    // Link tags back to video and mark completed
    video.tags = savedTags.map(t => t._id);
    video.status = 'completed';
    await video.save();
  } catch (err) {
    video.status = 'failed';
    await video.save();
    return res.status(500).json({ success: false, error: 'Failed to save tags.', details: err.message });
  }

  // Step 6: Return full result to frontend
  return res.status(201).json({
    success: true,
    video: {
      video_id: video.video_id,
      video_name: video.video_name,
      status: video.status,
      upload_time: video.upload_time
    },
    inference: inferenceResult,
    tags: savedTags.map(t => ({
      tag_name: t.tag_name,
      confidence_score: t.confidence_score
    }))
  });
};

/**
 * Get tags for a specific video
 */
export const getTagsForVideo = async (req, res) => {
  try {
    const { video_id } = req.params;
    const video = await Video.findOne({ video_id });
    if (!video) {
      return res.status(404).json({ success: false, error: 'Video not found.' });
    }
    const tags = await VideoTag.find({ video_id }).sort({ confidence_score: -1 });
    return res.status(200).json({ success: true, video_id, tags });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
};

/**
 * Get all videos with their tags
 */
export const getAllVideos = async (req, res) => {
  try {
    const videos = await Video.find().sort({ upload_time: -1 }).populate('tags');
    return res.status(200).json({ success: true, videos });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
};

/**
 * Get a single video by ID with tags
 */
export const getVideoById = async (req, res) => {
  try {
    const { video_id } = req.params;
    const video = await Video.findOne({ video_id }).populate('tags');
    if (!video) {
      return res.status(404).json({ success: false, error: 'Video not found.' });
    }
    return res.status(200).json({ success: true, video });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
};
