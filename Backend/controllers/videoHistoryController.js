import VideoHistory from '../models/VideoHistory.js';
import Media from '../models/Media.js';
import Tag from '../models/Tag.js';

export const getVideoHistory = async (req, res, next) => {
  try {
    const { mediaId } = req.query;

    if (!mediaId) {
      return res.status(400).json({
        success: false,
        error: 'mediaId query parameter is required'
      });
    }

    const history = await VideoHistory.find({ mediaId })
      .populate('media', 'mediaId fileName fileUrl mediaType')
      .populate('tag', 'tagId tagName fileType')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: history.length,
      data: history
    });
  } catch (error) {
    next(error);
  }
};

export const createVideoHistory = async (req, res, next) => {
  try {
    const { mediaId, tagId, confidenceScore } = req.body;

    if (!mediaId || !tagId || confidenceScore === undefined) {
      return res.status(400).json({
        success: false,
        error: 'mediaId, tagId, and confidenceScore are required'
      });
    }

    const media = await Media.findOne({ mediaId });
    if (!media) {
      return res.status(404).json({
        success: false,
        error: 'Media not found'
      });
    }

    const tag = await Tag.findOne({ tagId });
    if (!tag) {
      return res.status(404).json({
        success: false,
        error: 'Tag not found'
      });
    }

    if (tag.fileType !== 'video') {
      return res.status(400).json({
        success: false,
        error: 'Tag must be associated with video type'
      });
    }

    if (tag.mediaId !== media.mediaId) {
      return res.status(400).json({
        success: false,
        error: 'Tag does not belong to the provided mediaId'
      });
    }

    const entry = await VideoHistory.create({
      mediaId,
      media: media._id,
      tagId,
      tag: tag._id,
      confidenceScore
    });

    await entry.populate('media', 'mediaId fileName fileUrl mediaType');
    await entry.populate('tag', 'tagId tagName fileType');

    res.status(201).json({
      success: true,
      message: 'Video history entry created successfully',
      data: entry
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

