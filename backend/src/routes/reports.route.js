const express = require('express');
const router = express.Router();
const { syncReporte, getReportes, updateReporte, deleteReporte } = require('../controllers/reports.controller');

router.post('/', syncReporte);
router.get('/', getReportes);
router.put('/:id', updateReporte);
router.delete('/:id', deleteReporte);

module.exports = router;
