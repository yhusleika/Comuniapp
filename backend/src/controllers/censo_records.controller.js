const CensoRecord = require('../models/censo_record.model');

const syncCensoRecord = async (req, res) => {
    try {
        const data = req.body;
        delete data.isSynced;
        const record = await CensoRecord.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: "Registro de censo sincronizado", data: record });
    } catch (error) {
        console.error('Error sincronizando registro de censo:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

const getCensoRecords = async (req, res) => {
    try {
        const filter = req.query.censoId ? { censoId: req.query.censoId } : {};
        const records = await CensoRecord.find(filter);
        res.status(200).json({ success: true, data: records });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const updateCensoRecord = async (req, res) => {
    try {
        const data = req.body;
        delete data.isSynced;
        const record = await CensoRecord.findOneAndUpdate({ id: req.params.id }, data, { new: true });
        if (!record) return res.status(404).json({ success: false, message: "Registro no encontrado" });
        res.status(200).json({ success: true, message: "Registro actualizado", data: record });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteCensoRecord = async (req, res) => {
    try {
        const record = await CensoRecord.findOneAndDelete({ id: req.params.id });
        if (!record) return res.status(404).json({ success: false, message: "Registro no encontrado" });
        res.status(200).json({ success: true, message: "Registro eliminado" });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncCensoRecord, getCensoRecords, updateCensoRecord, deleteCensoRecord };
