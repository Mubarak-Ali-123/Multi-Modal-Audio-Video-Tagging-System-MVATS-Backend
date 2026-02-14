import Media from '../models/Media.js';
import { detectFileType } from '../utils/fileUpload.js';
import fs from 'fs';

/**
 * Create media entry (file upload or remote URL)
 */
export const uploadMedia = async (req, res, next) => {
  try {
    console.log('Upload Media - req.body:', req.body);
    console.log('Upload Media - req.file:', req.file ? 'File present' : 'No file');

    let fileName = null;
    let fileUrl = null;
    let mediaType = req.body.mediaType || req.body.fileType;

    if (req.file) {
      const file = req.file;
      fileName = file.originalname;
      fileUrl = `/uploads/${file.filename}`;
      mediaType = mediaType || detectFileType(file.originalname, file.mimetype);
    } else if (req.body.fileUrl) {
      fileUrl = req.body.fileUrl;
      fileName = req.body.fileName || fileUrl.split('/').pop() || 'media';
      mediaType = mediaType || detectFileType(fileName, '');
    } else {
      return res.status(400).json({
        success: false,
        error: 'Either a file or fileUrl must be provided'
      });
    }

    if (!mediaType || !['audio', 'video', 'fusion'].includes(mediaType)) {
      return res.status(400).json({
        success: false,
        error: 'mediaType must be "audio", "video", or "fusion"'
      });
    }

    const media = await Media.create({
      fileName,
      fileUrl,
      mediaType,
      enteredAt: new Date()
    });

    res.status(201).json({
      success: true,
      message: 'Media entry created successfully',
      data: media,
      mediaId: media.mediaId
    });
  } catch (error) {
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (unlinkError) {
        console.error('Error deleting file:', unlinkError);
      }
    }

    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        error: messages.join(', ')
      });
    }
    next(error);
  }
};

export const getMediaById = async (req, res, next) => {
  try {
    const media = await Media.findOne({ mediaId: req.params.id }) || await Media.findById(req.params.id);

    if (!media) {
      return res.status(404).json({
        success: false,
        error: 'Media not found'
      });
    }

    res.status(200).json({
      success: true,
      data: media
    });
  } catch (error) {
    next(error);
  }
};

export const getAllMedia = async (req, res, next) => {
  try {
    const { mediaType } = req.query;
    const query = {};

    if (mediaType) {
      if (!['audio', 'video', 'fusion'].includes(mediaType)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid mediaType. Must be "audio", "video", or "fusion"'
        });
      }
      query.mediaType = mediaType;
    }

    const media = await Media.find(query).sort({ enteredAt: -1 });

    res.status(200).json({
      success: true,
      count: media.length,
      data: media
    });
  } catch (error) {
    next(error);
  }
};
