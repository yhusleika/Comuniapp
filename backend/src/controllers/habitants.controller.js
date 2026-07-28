const Habitante = require('../models/habitante.model');
const { getPagination, getPaginationMeta } = require('../utils/pagination');
const { createSyncController, createUpdateController, createDeleteController } = require('../utils/crudFactory');

const syncHabitante = createSyncController(Habitante);
const updateHabitante = createUpdateController(Habitante);
const deleteHabitante = createDeleteController(Habitante);

const getHabitantes = async (req, res) => {
    try {
        const { page, limit, skip } = getPagination(req.query);
        const { search } = req.query;
        let query = {};

        if (search && search.trim().length > 0) {
            const searchString = search.trim();
            query.$or = [
                { cedula: { $regex: searchString, $options: 'i' } },
                { nombres: { $regex: searchString, $options: 'i' } },
                { apellidos: { $regex: searchString, $options: 'i' } },
            ];
        }

        const [habitantes, total] = await Promise.all([
            Habitante.find(query).skip(skip).limit(limit),
            Habitante.countDocuments(query),
        ]);

        res.status(200).json({
            success: true,
            data: habitantes,
            pagination: getPaginationMeta(total, page, limit),
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncHabitante, getHabitantes, updateHabitante, deleteHabitante };
