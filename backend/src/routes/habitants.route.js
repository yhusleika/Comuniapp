const express = require('express');
const router = express.Router();
const { syncHabitante, getHabitantes } = require('../controllers/habitants.controller');

// Ruta principal: POST /v1/habitants (Para sincronizar)
router.post('/', syncHabitante);

// Ruta para obtener todos (útil para revisar desde Postman o navegador)
router.get('/', getHabitantes);

module.exports = router;
