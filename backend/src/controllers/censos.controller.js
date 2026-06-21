const Censo = require('../models/censo.model');

// Crear o actualizar un censo (Upsert)
const syncCenso = async (req, res) => {
    try {
        const censoData = req.body;
        delete censoData.isSynced;

        const censo = await Censo.findOneAndUpdate(
            { id: censoData.id },
            censoData,
            { new: true, upsert: true }
        );

        res.status(200).json({
            success: true,
            message: "Censo sincronizado exitosamente",
            data: censo
        });
    } catch (error) {
        console.error('Error sincronizando censo:', error);
        res.status(500).json({
            success: false,
            message: "Error al sincronizar censo",
            error: error.message
        });
    }
};

// Obtener todos los censos
const getCensos = async (req, res) => {
    try {
        const censos = await Censo.find();
        res.status(200).json({ success: true, data: censos });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncCenso, getCensos };
