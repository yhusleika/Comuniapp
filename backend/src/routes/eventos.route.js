const express = require('express');
const router = express.Router();
const { syncEvento, getEventos, updateEvento, deleteEvento } = require('../controllers/eventos.controller');

router.post('/', syncEvento);
router.get('/', getEventos);
router.put('/:id', updateEvento);
router.delete('/:id', deleteEvento);

module.exports = router;
