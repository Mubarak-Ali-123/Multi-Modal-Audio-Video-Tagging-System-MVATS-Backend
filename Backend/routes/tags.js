import express from 'express';
import { body } from 'express-validator';
import { getAllTags, getTagById, createTag } from '../controllers/tagController.js';
import { validate } from '../utils/validation.js';

const router = express.Router();

const tagValidation = [
  body('tagName')
    .trim()
    .notEmpty()
    .withMessage('tagName is required'),
  body('fileType')
    .isIn(['audio', 'video', 'fusion'])
    .withMessage('fileType must be "audio", "video", or "fusion"'),
  body('mediaId')
    .trim()
    .notEmpty()
    .withMessage('mediaId is required')
];

router.get('/', getAllTags);
router.get('/:id', getTagById);
router.post('/', tagValidation, validate, createTag);

export default router;

