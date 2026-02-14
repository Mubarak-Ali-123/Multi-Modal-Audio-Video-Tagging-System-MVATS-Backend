import express from 'express';
import { body, query } from 'express-validator';
import { getVideoHistory, createVideoHistory } from '../controllers/videoHistoryController.js';
import { validate } from '../utils/validation.js';

const router = express.Router();

/**
 * Validation rules for creating video history
 */
const videoHistoryValidation = [
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
const getVideoHistoryValidation = [
  query('mediaId')
    .trim()
    .notEmpty()
    .withMessage('mediaId query parameter is required')
];

/**
 * @route   GET /api/history/video
 * @desc    Get all video predictions for a specific media_id
 * @query   media_id (required) - The media ID to get predictions for
 * @access  Public
 */
router.get('/', getVideoHistoryValidation, validate, getVideoHistory);

/**
 * @route   POST /api/history/video
 * @desc    Create a new video prediction
 * @access  Public
 */
router.post('/', videoHistoryValidation, validate, createVideoHistory);

export default router;

