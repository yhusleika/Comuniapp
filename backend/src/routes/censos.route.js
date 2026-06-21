const express = require('express');
const router = express.Router();
const { syncCenso, getCensos } = require('../controllers/censos.controller');

router.post('/', syncCenso);
router.get('/', getCensos);

module.exports = router;
