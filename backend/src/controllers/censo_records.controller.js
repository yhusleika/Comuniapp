const CensoRecord = require('../models/censo_record.model');

// Crear o actualizar un registro de censo (Upsert)
const syncCensoRecord = async (req, res) => {
    try {
        const recordData = req.body;
        delete recordData.isSynced;

        const censoRecord = await CensoRecord.findOneAndUpdate(
            { id: recordData.id },
            recordData,
            { new: true, upsert: true }
        );

        res.status(200).json({
            success: true,
            message: "Registro de censo sincronizado exitosamente",
            data: censoRecord
        });
    } catch (error) {
        console.error('Error sincronizando registro de censo:', error);
        res.status(500).json({
            success: false,
            message: "Error al sincronizar registro de censo",
            error: error.message
        });
    }
};

// Obtener todos los registros de censo (opcionalmente filtrados por censoId)
const getCensoRecords = async (req, res) => {
    try {
        const filter = req.query.censoId ? { censoId: req.query.censoId } : {};
        const records = await CensoRecord.find(filter);
        res.status(200).json({ success: true, data: records });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncCensoRecord, getCensoRecords };
