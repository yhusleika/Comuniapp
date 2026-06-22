const express = require('express');
const router = express.Router();
const { syncAuditoria, getAuditoria } = require('../controllers/auditoria.controller');

router.post('/', syncAuditoria);
router.get('/', getAuditoria);

module.exports = router;
