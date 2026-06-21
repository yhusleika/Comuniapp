const express = require('express');
const router = express.Router();
const { syncReporte, getReportes } = require('../controllers/reports.controller');

router.post('/', syncReporte);
router.get('/', getReportes);

module.exports = router;
