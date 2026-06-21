const Habitante = require('../models/habitante.model');

// Crear o actualizar un habitante (Upsert)
const syncHabitante = async (req, res) => {
    try {
        const habitanteData = req.body;
        delete habitanteData.isSynced;

        const habitante = await Habitante.findOneAndUpdate(
            { id: habitanteData.id },
            habitanteData,
            { new: true, upsert: true }
        );

        res.status(200).json({
            success: true,
            message: "Habitante sincronizado exitosamente",
            data: habitante
        });
    } catch (error) {
        console.error('Error sincronizando habitante:', error);
        res.status(500).json({ success: false, message: "Error al sincronizar habitante", error: error.message });
    }
};

// Obtener todos los habitantes
const getHabitantes = async (req, res) => {
    try {
        const habitantes = await Habitante.find();
        res.status(200).json({ success: true, data: habitantes });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Actualizar un habitante por su campo id
const updateHabitante = async (req, res) => {
    try {
        const habitanteData = req.body;
        delete habitanteData.isSynced;

        const habitante = await Habitante.findOneAndUpdate(
            { id: req.params.id },
            habitanteData,
            { new: true }
        );

        if (!habitante) {
            return res.status(404).json({ success: false, message: "Habitante no encontrado" });
        }

        res.status(200).json({ success: true, message: "Habitante actualizado", data: habitante });
    } catch (error) {
        console.error('Error actualizando habitante:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

// Eliminar un habitante por su campo id
const deleteHabitante = async (req, res) => {
    try {
        const habitante = await Habitante.findOneAndDelete({ id: req.params.id });

        if (!habitante) {
            return res.status(404).json({ success: false, message: "Habitante no encontrado" });
        }

        res.status(200).json({ success: true, message: "Habitante eliminado" });
    } catch (error) {
        console.error('Error eliminando habitante:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncHabitante, getHabitantes, updateHabitante, deleteHabitante };
