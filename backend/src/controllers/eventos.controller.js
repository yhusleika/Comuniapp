const Evento = require('../models/evento.model');
const { getPagination, getPaginationMeta } = require('../utils/pagination');
const { createSyncController, createUpdateController, createDeleteController } = require('../utils/crudFactory');

const syncEvento = createSyncController(Evento, { deleteIsSynced: false });
const updateEvento = createUpdateController(Evento, { deleteIsSynced: false });
const deleteEvento = createDeleteController(Evento);

const getEventos = async (req, res) => {
    try {
        const { page, limit, skip } = getPagination(req.query);
        const filter = req.query.category ? { category: req.query.category } : {};

        const [eventos, total] = await Promise.all([
            Evento.find(filter).sort({ date: -1 }).skip(skip).limit(limit),
            Evento.countDocuments(filter),
        ]);

        res.status(200).json({
            success: true,
            data: eventos,
            pagination: getPaginationMeta(total, page, limit),
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncEvento, getEventos, updateEvento, deleteEvento };
