const express = require('express');
const router = express.Router();
const { syncCenso, getCensos, updateCenso, deleteCenso } = require('../controllers/censos.controller');
const { requireRole } = require('../middleware/role.middleware');

router.post('/', syncCenso);
router.get('/', getCensos);
router.put('/:id', updateCenso);
router.delete('/:id', requireRole('admin'), deleteCenso);

module.exports = router;
