import mongoose from 'mongoose';

/**
 * VideoHistory Schema
 * Stores video predictions linked to tags & media
 */
const videoHistorySchema = new mongoose.Schema({
  mediaId: {
    type: String,
    required: [true, 'Media ID is required'],
    index: true
  },
  media: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Media'
  },
  tagId: {
    type: String,
    required: [true, 'Tag ID is required'],
    index: true
  },
  tag: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tag'
  },
  confidenceScore: {
    type: Number,
    required: [true, 'Confidence score is required'],
    min: [0, 'Confidence score must be between 0 and 1'],
    max: [1, 'Confidence score must be between 0 and 1']
  }
}, {
  timestamps: true,
  collection: 'video_history'
});

videoHistorySchema.index({ mediaId: 1, createdAt: -1 });
videoHistorySchema.index({ tagId: 1, createdAt: -1 });

const VideoHistory = mongoose.model('VideoHistory', videoHistorySchema);

export default VideoHistory;

