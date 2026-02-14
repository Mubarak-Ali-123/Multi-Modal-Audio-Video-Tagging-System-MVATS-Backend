import mongoose from 'mongoose';

/**
 * Tag Schema
 * Associates a tag with a media entry and media type
 */
const tagSchema = new mongoose.Schema({
  tagId: {
    type: String,
    required: true,
    unique: true,
    default: () => `tag_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    index: true
  },
  tagName: {
    type: String,
    required: [true, 'Tag name is required'],
    trim: true
  },
  fileType: {
    type: String,
    required: [true, 'File type is required'],
    enum: {
      values: ['audio', 'video', 'fusion'],
      message: 'File type must be "audio", "video", or "fusion"'
    },
    index: true
  },
  mediaId: {
    type: String,
    required: [true, 'Media ID is required'],
    index: true
  },
  media: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Media',
    required: [true, 'Media reference is required']
  }
}, {
  timestamps: true,
  collection: 'tags'
});

tagSchema.index({ mediaId: 1, tagName: 1 }, { unique: true });

const Tag = mongoose.model('Tag', tagSchema);

export default Tag;




