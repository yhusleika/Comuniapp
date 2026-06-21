const Reporte = require('../models/reporte.model');

const syncReporte = async (req, res) => {
    try {
        const data = req.body;
        delete data.isSynced;
        const reporte = await Reporte.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: "Reporte sincronizado", data: reporte });
    } catch (error) {
        console.error('Error sincronizando reporte:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

const getReportes = async (req, res) => {
    try {
        const reportes = await Reporte.find();
        res.status(200).json({ success: true, data: reportes });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const updateReporte = async (req, res) => {
    try {
        const data = req.body;
        delete data.isSynced;
        const reporte = await Reporte.findOneAndUpdate({ id: req.params.id }, data, { new: true });
        if (!reporte) return res.status(404).json({ success: false, message: "Reporte no encontrado" });
        res.status(200).json({ success: true, message: "Reporte actualizado", data: reporte });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteReporte = async (req, res) => {
    try {
        const reporte = await Reporte.findOneAndDelete({ id: req.params.id });
        if (!reporte) return res.status(404).json({ success: false, message: "Reporte no encontrado" });
        res.status(200).json({ success: true, message: "Reporte eliminado" });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncReporte, getReportes, updateReporte, deleteReporte };
