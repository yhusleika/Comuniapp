const express = require('express');
const router = express.Router();
const { syncAyuda, getAyudas, updateAyuda, deleteAyuda } = require('../controllers/ayudas.controller');
const { verifyToken, authorizeRoles } = require('../middleware/auth.middleware');

router.post('/', syncAyuda);
router.get('/', getAyudas);
router.put('/:id', updateAyuda);
router.delete('/:id', authorizeRoles('admin'), deleteAyuda);

module.exports = router;
