const express = require('express');
const router = express.Router();
const { syncAyuda, getAyudas, updateAyuda, deleteAyuda } = require('../controllers/ayudas.controller');
const { requireRole } = require('../middleware/role.middleware');

router.post('/', syncAyuda);
router.get('/', getAyudas);
router.put('/:id', updateAyuda);
router.delete('/:id', requireRole('admin'), deleteAyuda);

module.exports = router;
