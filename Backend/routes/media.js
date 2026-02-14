import express from 'express';
import { uploadMedia, getMediaById, getAllMedia } from '../controllers/mediaController.js';
import { upload } from '../utils/fileUpload.js';

const router = express.Router();

/**
 * Custom validation middleware that works with both multipart and JSON
 */
const validateUpload = (req, res, next) => {
  // Debug logging
  console.log('Validation - req.body:', req.body);
  console.log('Validation - req.file:', req.file ? 'File present' : 'No file');
  
  // If no file and no fileUrl, return error
  if (!req.file && !req.body.fileUrl) {
    console.log('Validation failed: Neither file nor fileUrl provided');
    return res.status(400).json({
      success: false,
      error: 'Either a file or fileUrl must be provided',
      details: 'Please select a file to upload or provide a file URL'
    });
  }

  // If fileUrl is provided, validate it's a URL
  if (req.body.fileUrl && !req.file) {
    try {
      new URL(req.body.fileUrl);
    } catch {
      console.log('Validation failed: Invalid URL format:', req.body.fileUrl);
      return res.status(400).json({
        success: false,
        error: 'File URL must be a valid URL',
        details: `Invalid URL format: ${req.body.fileUrl}`
      });
    }
  }

  console.log('Validation passed');
  next();
};

/**
 * Error handler for multer
 */
const handleMulterError = (err, req, res, next) => {
  if (err) {
    console.error('Multer error:', err);
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        error: 'File too large',
        details: 'Maximum file size is 500MB'
      });
    }
    if (err.message === 'Only video and audio files are allowed') {
      return res.status(400).json({
        success: false,
        error: 'Invalid file type',
        details: err.message
      });
    }
    return res.status(400).json({
      success: false,
      error: 'File upload error',
      details: err.message
    });
  }
  next();
};

/**
 * @route   POST /media/upload
 * @desc    Upload media (file or URL)
 * @access  Public
 * Handles both multipart/form-data (file upload) and JSON (URL upload)
 */
router.post('/upload', 
  upload.single('file'), // Handle file upload if present (must be before validation)
  handleMulterError, // Handle multer errors
  validateUpload, // Custom validation that works with multipart
  uploadMedia
);

/**
 * @route   GET /media
 * @desc    Get all media entries (optional filters: userId, fileType, status)
 * @query   userId (optional) - Filter by user ID
 * @query   fileType (optional) - Filter by file type (video, audio, fusion)
 * @query   status (optional) - Filter by status (uploaded, processing, done)
 * @access  Public
 */
router.get('/', getAllMedia);

/**
 * @route   GET /media/:id
 * @desc    Get a single media entry by ID
 * @access  Public
 */
router.get('/:id', getMediaById);

export default router;
