import AudioHistory from '../models/AudioHistory.js';
import VideoHistory from '../models/VideoHistory.js';
import FusionHistory from '../models/FusionHistory.js';

const mapEntry = (entry, type) => ({
  id: entry._id,
  type,
  mediaId: entry.mediaId,
  tagId: entry.tagId,
  confidenceScore: entry.confidenceScore,
  createdAt: entry.createdAt,
  updatedAt: entry.updatedAt,
  media: entry.media,
  tag: entry.tag
});

export const getHistoryByMedia = async (req, res, next) => {
  try {
    const { mediaId } = req.params;
    const { type, limit = 100 } = req.query;

    if (!mediaId) {
      return res.status(400).json({
        success: false,
        error: 'mediaId parameter is required'
      });
    }

    const queries = [];
    if (!type || type === 'audio') {
      queries.push({
        type: 'audio',
        promise: AudioHistory.find({ mediaId }).populate('media').populate('tag').sort({ createdAt: -1 }).limit(Number(limit))
      });
    }
    if (!type || type === 'video') {
      queries.push({
        type: 'video',
        promise: VideoHistory.find({ mediaId }).populate('media').populate('tag').sort({ createdAt: -1 }).limit(Number(limit))
      });
    }
    if (!type || type === 'fusion') {
      queries.push({
        type: 'fusion',
        promise: FusionHistory.find({ mediaId }).populate('media').populate('tag').sort({ createdAt: -1 }).limit(Number(limit))
      });
    }

    const results = await Promise.all(queries.map(q => q.promise));
    const merged = [];
    results.forEach((data, idx) => {
      const label = queries[idx].type;
      data.forEach(entry => merged.push(mapEntry(entry, label)));
    });

    merged.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.status(200).json({
      success: true,
      count: merged.length,
      data: merged.slice(0, Number(limit))
    });
  } catch (error) {
    next(error);
  }
};

export const getAllHistory = async (req, res, next) => {
  try {
    const { type, limit = 100 } = req.query;

    const queries = [];
    if (!type || type === 'audio') {
      queries.push({
        type: 'audio',
        promise: AudioHistory.find().populate('media').populate('tag').sort({ createdAt: -1 }).limit(Number(limit))
      });
    }
    if (!type || type === 'video') {
      queries.push({
        type: 'video',
        promise: VideoHistory.find().populate('media').populate('tag').sort({ createdAt: -1 }).limit(Number(limit))
      });
    }
    if (!type || type === 'fusion') {
      queries.push({
        type: 'fusion',
        promise: FusionHistory.find().populate('media').populate('tag').sort({ createdAt: -1 }).limit(Number(limit))
      });
    }

    const results = await Promise.all(queries.map(q => q.promise));
    const merged = [];
    results.forEach((data, idx) => {
      const label = queries[idx].type;
      data.forEach(entry => merged.push(mapEntry(entry, label)));
    });

    merged.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.status(200).json({
      success: true,
      count: merged.length,
      data: merged.slice(0, Number(limit))
    });
  } catch (error) {
    next(error);
  }
};

