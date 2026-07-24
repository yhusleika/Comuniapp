const Sector = require('../models/sector.model');

const getSectores = async (req, res) => {
    try {
        const sectores = await Sector.find().sort({ createdAt: 1 });
        res.status(200).json({ success: true, data: sectores });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const createSector = async (req, res) => {
    try {
        const data = req.body;
        const newSector = await Sector.findOneAndUpdate({ id: data.id }, data, { new: true, upsert: true });
        res.status(200).json({ success: true, message: 'Sector guardado', data: newSector });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const updateSector = async (req, res) => {
    try {
        const { id } = req.params;
        const updated = await Sector.findOneAndUpdate({ id }, req.body, { new: true });
        res.status(200).json({ success: true, message: 'Sector actualizado', data: updated });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteSector = async (req, res) => {
    try {
        const { id } = req.params;
        await Sector.findOneAndDelete({ id });
        res.status(200).json({ success: true, message: 'Sector eliminado' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getSectores, createSector, updateSector, deleteSector };
