const express = require('express');
const router = express.Router();
const { syncCensoRecord, getCensoRecords } = require('../controllers/censo_records.controller');

router.post('/', syncCensoRecord);
router.get('/', getCensoRecords);

module.exports = router;
