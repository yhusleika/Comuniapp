const Auditoria = require('../models/auditoria.model');

const syncAuditoria = async (req, res) => {
    try {
        const data = req.body;
        // Upsert by id
        const log = await Auditoria.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: "Log sincronizado", data: log });
    } catch (error) {
        console.error('Error sincronizando auditoria:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

const getAuditoria = async (req, res) => {
    try {
        // Obtenemos los últimos 500 registros para no sobrecargar si hay muchos
        const logs = await Auditoria.find().sort({ dateTime: -1 }).limit(500);
        res.status(200).json({ success: true, data: logs });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncAuditoria, getAuditoria };
