const Reporte = require('../models/reporte.model');

// Crear o actualizar un reporte (Upsert)
const syncReporte = async (req, res) => {
    try {
        const reporteData = req.body;
        delete reporteData.isSynced;

        const reporte = await Reporte.findOneAndUpdate(
            { id: reporteData.id },
            reporteData,
            { new: true, upsert: true }
        );

        res.status(200).json({
            success: true,
            message: "Reporte sincronizado exitosamente",
            data: reporte
        });
    } catch (error) {
        console.error('Error sincronizando reporte:', error);
        res.status(500).json({
            success: false,
            message: "Error al sincronizar reporte",
            error: error.message
        });
    }
};

// Obtener todos los reportes
const getReportes = async (req, res) => {
    try {
        const reportes = await Reporte.find();
        res.status(200).json({ success: true, data: reportes });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncReporte, getReportes };
