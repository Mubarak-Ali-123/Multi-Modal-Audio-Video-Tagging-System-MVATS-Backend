import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Configure multer for file uploads
 * Stores files in uploads directory
 */
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads/'));
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

/**
 * File filter - only allow video and audio files
 */
const fileFilter = (req, file, cb) => {
  // Check MIME type
  if (file.mimetype.startsWith('video/') || file.mimetype.startsWith('audio/')) {
    cb(null, true);
  } else {
    cb(new Error('Only video and audio files are allowed'), false);
  }
};

/**
 * Multer upload configuration
 */
export const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 500 * 1024 * 1024 // 500MB limit
  }
});

/**
 * Detect file type from filename or MIME type
 */
export const detectFileType = (filename, mimetype = '') => {
  // Check MIME type first
  if (mimetype) {
    if (mimetype.startsWith('video/')) return 'video';
    if (mimetype.startsWith('audio/')) return 'audio';
  }

  // Fallback to file extension
  if (!filename) return 'video'; // Default
  
  const lower = filename.toLowerCase();
  
  // Video extensions
  const videoExts = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
  if (videoExts.some(ext => lower.includes(ext))) return 'video';
  
  // Audio extensions
  const audioExts = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a'];
  if (audioExts.some(ext => lower.includes(ext))) return 'audio';
  
  // Default to video if uncertain
  return 'video';
};

