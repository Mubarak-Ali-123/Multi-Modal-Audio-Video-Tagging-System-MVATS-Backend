import mongoose from 'mongoose';

const videoTagSchema = new mongoose.Schema({
  tag_id: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  video_id: {
    type: String,
    required: true,
    index: true
  },
  video: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Video'
  },
  tag_name: {
    type: String,
    required: true
  },
  confidence_score: {
    type: Number,
    required: true,
    min: 0,
    max: 1
  },
  created_at: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  collection: 'video_tags'
});

videoTagSchema.index({ video_id: 1, confidence_score: -1 });

const VideoTag = mongoose.model('VideoTag', videoTagSchema);
export default VideoTag;