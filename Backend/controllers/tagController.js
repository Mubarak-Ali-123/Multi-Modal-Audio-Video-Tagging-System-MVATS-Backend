import Tag from '../models/Tag.js';
import Media from '../models/Media.js';

/**
 * Get tags (optionally filtered by mediaId or fileType)
 */
export const getAllTags = async (req, res, next) => {
  try {
    const { mediaId, fileType } = req.query;
    const query = {};

    if (mediaId) {
      query.mediaId = mediaId;
    }

    if (fileType) {
      if (!['audio', 'video', 'fusion'].includes(fileType)) {
        return res.status(400).json({
          success: false,
          error: 'fileType must be "audio", "video", or "fusion"'
        });
      }
      query.fileType = fileType;
    }

    const tags = await Tag.find(query).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: tags.length,
      data: tags
    });
  } catch (error) {
    next(error);
  }
};

export const getTagById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const tag = await Tag.findOne({ tagId: id }) || await Tag.findById(id);

    if (!tag) {
      return res.status(404).json({
        success: false,
        error: 'Tag not found'
      });
    }

    res.status(200).json({
      success: true,
      data: tag
    });
  } catch (error) {
    next(error);
  }
};

export const createTag = async (req, res, next) => {
  try {
    const { tagName, fileType, mediaId } = req.body;

    if (!tagName || !fileType || !mediaId) {
      return res.status(400).json({
        success: false,
        error: 'tagName, fileType, and mediaId are required'
      });
    }

    if (!['audio', 'video', 'fusion'].includes(fileType)) {
      return res.status(400).json({
        success: false,
        error: 'fileType must be "audio", "video", or "fusion"'
      });
    }

    const media = await Media.findOne({ mediaId });
    if (!media) {
      return res.status(404).json({
        success: false,
        error: 'Media not found'
      });
    }

    const tag = await Tag.create({
      tagName,
      fileType,
      mediaId,
      media: media._id
    });

    res.status(201).json({
      success: true,
      data: tag
    });
  } catch (error) {
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

