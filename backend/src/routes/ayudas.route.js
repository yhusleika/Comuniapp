const express = require('express');
const router = express.Router();
const { syncAyuda, getAyudas, updateAyuda, deleteAyuda } = require('../controllers/ayudas.controller');

router.post('/', syncAyuda);
router.get('/', getAyudas);
router.put('/:id', updateAyuda);
router.delete('/:id', deleteAyuda);

module.exports = router;
