const Habitante = require('../models/habitante.model');

// Crear o actualizar un habitante (Upsert)
const syncHabitante = async (req, res) => {
    try {
        const habitanteData = req.body;

        // Eliminamos el campo isSynced antes de guardar, ya que es un estado puramente local (del móvil)
        delete habitanteData.isSynced;

        // Buscamos si ya existe el habitante por su id (generado en Hive)
        // Si existe lo actualiza, si no existe lo crea (upsert: true)
        const habitante = await Habitante.findOneAndUpdate(
            { id: habitanteData.id },
            habitanteData,
            { new: true, upsert: true }
        );

        // Devolvemos el formato exacto que espera la app de Flutter
        res.status(200).json({
            success: true,
            message: "Habitante sincronizado exitosamente",
            data: habitante
        });
    } catch (error) {
        console.error('Error sincronizando habitante:', error);
        res.status(500).json({
            success: false,
            message: "Error al sincronizar habitante",
            error: error.message
        });
    }
};

// Obtener todos los habitantes (Opcional, útil para pruebas)
const getHabitantes = async (req, res) => {
    try {
        const habitantes = await Habitante.find();
        res.status(200).json({
            success: true,
            data: habitantes
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = {
    syncHabitante,
    getHabitantes
};
