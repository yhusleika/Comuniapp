const express = require('express');
const router = express.Router();
const { syncCenso, getCensos, updateCenso, deleteCenso } = require('../controllers/censos.controller');
const { verifyToken, authorizeRoles } = require('../middleware/auth.middleware');

router.post('/', syncCenso);
router.get('/', getCensos);
router.put('/:id', updateCenso);
router.delete('/:id', authorizeRoles('admin'), deleteCenso);

module.exports = router;
