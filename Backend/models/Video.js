import mongoose from 'mongoose';

const videoSchema = new mongoose.Schema({
  video_id: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  user_id: {
    type: String,
    default: 'anonymous'
  },
  video_name: {
    type: String,
    required: true
  },
  video_path: {
    type: String,
    required: true
  },
  duration: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['uploaded', 'processing', 'completed', 'failed'],
    default: 'uploaded'
  },
  upload_time: {
    type: Date,
    default: Date.now
  },
  tags: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'VideoTag'
  }]
}, {
  timestamps: true,
  collection: 'videos'
});

const Video = mongoose.model('Video', videoSchema);
export default Video;