const express = require('express');
const router = express.Router();
const { syncHabitante, getHabitantes, updateHabitante, deleteHabitante } = require('../controllers/habitants.controller');

router.post('/', syncHabitante);
router.get('/', getHabitantes);
router.put('/:id', updateHabitante);
router.delete('/:id', deleteHabitante);

module.exports = router;
