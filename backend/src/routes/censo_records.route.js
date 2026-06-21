const express = require('express');
const router = express.Router();
const { syncCensoRecord, getCensoRecords, updateCensoRecord, deleteCensoRecord } = require('../controllers/censo_records.controller');

router.post('/', syncCensoRecord);
router.get('/', getCensoRecords);
router.put('/:id', updateCensoRecord);
router.delete('/:id', deleteCensoRecord);

module.exports = router;
