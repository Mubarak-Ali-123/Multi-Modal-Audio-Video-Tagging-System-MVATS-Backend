import express from 'express';
import { body, query } from 'express-validator';
import { getFusionHistory, createFusionHistory } from '../controllers/fusionHistoryController.js';
import { validate } from '../utils/validation.js';

const router = express.Router();

/**
 * Validation rules for creating fusion history
 */
const fusionHistoryValidation = [
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
const getFusionHistoryValidation = [
  query('mediaId')
    .trim()
    .notEmpty()
    .withMessage('mediaId query parameter is required')
];

/**
 * @route   GET /api/history/fusion
 * @desc    Get all fusion predictions for a specific media_id
 * @query   media_id (required) - The media ID to get predictions for
 * @access  Public
 */
router.get('/', getFusionHistoryValidation, validate, getFusionHistory);

/**
 * @route   POST /api/history/fusion
 * @desc    Create a new fusion prediction
 * @access  Public
 */
router.post('/', fusionHistoryValidation, validate, createFusionHistory);

export default router;

