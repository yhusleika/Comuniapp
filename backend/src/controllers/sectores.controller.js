const Sector = require('../models/sector.model');
const { getPagination, getPaginationMeta } = require('../utils/pagination');

const getSectores = async (req, res) => {
    try {
        const { page, limit, skip } = getPagination(req.query);
        const [sectores, total] = await Promise.all([
            Sector.find().sort({ createdAt: 1 }).skip(skip).limit(limit),
            Sector.countDocuments(),
        ]);
        res.status(200).json({
            success: true,
            data: sectores,
            pagination: getPaginationMeta(total, page, limit),
        });
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
        if (!updated) return res.status(404).json({ success: false, error: 'Sector no encontrado' });
        res.status(200).json({ success: true, message: 'Sector actualizado', data: updated });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

const deleteSector = async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await Sector.findOneAndDelete({ id });
        if (!deleted) return res.status(404).json({ success: false, error: 'Sector no encontrado' });
        res.status(200).json({ success: true, message: 'Sector eliminado' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getSectores, createSector, updateSector, deleteSector };
