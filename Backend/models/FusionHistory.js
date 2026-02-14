import mongoose from 'mongoose';

/**
 * FusionHistory Schema
 * Stores fusion predictions linked to tags & media
 */
const fusionHistorySchema = new mongoose.Schema({
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
    required: [true, 'Fusion confidence score is required'],
    min: [0, 'Fusion confidence score must be between 0 and 1'],
    max: [1, 'Fusion confidence score must be between 0 and 1']
  }
}, {
  timestamps: true,
  collection: 'fusion_history'
});

fusionHistorySchema.index({ mediaId: 1, createdAt: -1 });
fusionHistorySchema.index({ tagId: 1, createdAt: -1 });

const FusionHistory = mongoose.model('FusionHistory', fusionHistorySchema);

export default FusionHistory;

