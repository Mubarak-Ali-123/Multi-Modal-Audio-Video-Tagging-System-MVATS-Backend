import express from 'express';
import { body, query } from 'express-validator';
import { getAudioHistory, createAudioHistory } from '../controllers/audioHistoryController.js';
import { validate } from '../utils/validation.js';

const router = express.Router();

/**
 * Validation rules for creating audio history
 */
const audioHistoryValidation = [
  body('mediaId')
    .trim()
    .notEmpty()
    .withMessage('mediaId is required'),
  body('tagId')
    .trim()
    .notEmpty()
    .withMessage('tagId is required'),
  body('confidenceScore')
    .isFloat({ min: 0, max: 1 })
    .withMessage('confidenceScore must be between 0 and 1')
];

/**
 * Validation rules for query parameters
 */
const getAudioHistoryValidation = [
  query('mediaId')
    .trim()
    .notEmpty()
    .withMessage('mediaId query parameter is required')
];

/**
 * @route   GET /api/history/audio
 * @desc    Get all audio predictions for a specific media_id
 * @query   media_id (required) - The media ID to get predictions for
 * @access  Public
 */
router.get('/', getAudioHistoryValidation, validate, getAudioHistory);

/**
 * @route   POST /api/history/audio
 * @desc    Create a new audio prediction
 * @access  Public
 */
router.post('/', audioHistoryValidation, validate, createAudioHistory);

export default router;

