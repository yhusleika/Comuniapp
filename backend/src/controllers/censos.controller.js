const Censo = require('../models/censo.model');

const syncCenso = async (req, res) => {
    try {
        const data = req.body;
        delete data.isSynced;
        const censo = await Censo.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: "Censo sincronizado", data: censo });
    } catch (error) {
        console.error('Error sincronizando censo:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

const getCensos = async (req, res) => {
    try {
        const censos = await Censo.find();
        res.status(200).json({ success: true, data: censos });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const updateCenso = async (req, res) => {
    try {
        const data = req.body;
        delete data.isSynced;
        const censo = await Censo.findOneAndUpdate({ id: req.params.id }, data, { new: true });
        if (!censo) return res.status(404).json({ success: false, message: "Censo no encontrado" });
        res.status(200).json({ success: true, message: "Censo actualizado", data: censo });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteCenso = async (req, res) => {
    try {
        const censo = await Censo.findOneAndDelete({ id: req.params.id });
        if (!censo) return res.status(404).json({ success: false, message: "Censo no encontrado" });
        res.status(200).json({ success: true, message: "Censo eliminado" });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncCenso, getCensos, updateCenso, deleteCenso };
