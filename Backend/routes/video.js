import express from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { uploadAndClassify, getTagsForVideo, getAllVideos, getVideoById } from '../controllers/videoController.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Ensure uploads/videos directory exists
const uploadDir = path.join(__dirname, '..', 'uploads', 'videos');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer for video uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + '-' + file.originalname);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 500 * 1024 * 1024 }, // 500MB max
  fileFilter: (req, file, cb) => {
    const allowed = /mp4|avi|mov|mkv|webm|wmv|flv/;
    const ext = path.extname(file.originalname).toLowerCase().replace('.', '');
    if (allowed.test(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only video files are allowed (mp4, avi, mov, mkv, webm, wmv, flv)'));
    }
  }
});

// POST /video/upload — Full pipeline: upload → save → infer → tag → return
router.post('/upload', upload.single('video'), uploadAndClassify);

// GET /video/ — List all videos
router.get('/', getAllVideos);

// GET /video/:video_id — Get single video with tags
router.get('/:video_id', getVideoById);

// GET /video/:video_id/tags — Get tags for a video
router.get('/:video_id/tags', getTagsForVideo);

export default router;