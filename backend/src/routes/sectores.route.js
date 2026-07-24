const express = require('express');
const router = express.Router();
const { getSectores, createSector, updateSector, deleteSector } = require('../controllers/sectores.controller');

router.get('/', getSectores);
router.post('/', createSector);
router.put('/:id', updateSector);
router.delete('/:id', deleteSector);

module.exports = router;
