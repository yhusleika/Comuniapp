const Evento = require('../models/evento.model');

const syncEvento = async (req, res) => {
    try {
        const data = req.body;
        const evento = await Evento.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: "Evento sincronizado", data: evento });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const getEventos = async (req, res) => {
    try {
        const filter = req.query.category ? { category: req.query.category } : {};
        const eventos = await Evento.find(filter).sort({ date: -1 });
        res.status(200).json({ success: true, data: eventos });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const updateEvento = async (req, res) => {
    try {
        const evento = await Evento.findOneAndUpdate({ id: req.params.id }, req.body, { new: true });
        if (!evento) return res.status(404).json({ success: false, message: "Evento no encontrado" });
        res.status(200).json({ success: true, message: "Evento actualizado", data: evento });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteEvento = async (req, res) => {
    try {
        const evento = await Evento.findOneAndDelete({ id: req.params.id });
        if (!evento) return res.status(404).json({ success: false, message: "Evento no encontrado" });
        res.status(200).json({ success: true, message: "Evento eliminado" });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncEvento, getEventos, updateEvento, deleteEvento };
