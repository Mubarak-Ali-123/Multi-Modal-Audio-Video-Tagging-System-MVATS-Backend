import express from 'express';
import { getHistoryByMedia, getAllHistory } from '../controllers/historyController.js';

const router = express.Router();

router.get('/', getAllHistory);
router.get('/:mediaId', getHistoryByMedia);

export default router;

