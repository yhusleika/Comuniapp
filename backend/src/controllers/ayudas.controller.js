const Ayuda = require('../models/ayuda.model');

const syncAyuda = async (req, res) => {
    try {
        const data = req.body;
        const ayuda = await Ayuda.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: "Ayuda sincronizada", data: ayuda });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const getAyudas = async (req, res) => {
    try {
        const ayudas = await Ayuda.find();
        res.status(200).json({ success: true, data: ayudas });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const updateAyuda = async (req, res) => {
    try {
        const ayuda = await Ayuda.findOneAndUpdate({ id: req.params.id }, req.body, { new: true });
        if (!ayuda) return res.status(404).json({ success: false, message: "Ayuda no encontrada" });
        res.status(200).json({ success: true, message: "Ayuda actualizada", data: ayuda });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteAyuda = async (req, res) => {
    try {
        const ayuda = await Ayuda.findOneAndDelete({ id: req.params.id });
        if (!ayuda) return res.status(404).json({ success: false, message: "Ayuda no encontrada" });
        res.status(200).json({ success: true, message: "Ayuda eliminada" });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncAyuda, getAyudas, updateAyuda, deleteAyuda };
