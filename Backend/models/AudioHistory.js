import mongoose from 'mongoose';

/**
 * AudioHistory Schema
 * Stores audio predictions linked to tags & media
 */
const audioHistorySchema = new mongoose.Schema({
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
  collection: 'audio_history'
});

audioHistorySchema.index({ mediaId: 1, createdAt: -1 });
audioHistorySchema.index({ tagId: 1, createdAt: -1 });

const AudioHistory = mongoose.model('AudioHistory', audioHistorySchema);

export default AudioHistory;

