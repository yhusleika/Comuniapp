const CensoRecord = require('../models/censo_record.model');
const { getPagination, getPaginationMeta } = require('../utils/pagination');
const { createSyncController, createUpdateController, createDeleteController } = require('../utils/crudFactory');

const syncCensoRecord = createSyncController(CensoRecord);
const updateCensoRecord = createUpdateController(CensoRecord);
const deleteCensoRecord = createDeleteController(CensoRecord);

const getCensoRecords = async (req, res) => {
    try {
        const { page, limit, skip } = getPagination(req.query);
        const filter = req.query.censoId ? { censoId: req.query.censoId } : {};

        const [records, total] = await Promise.all([
            CensoRecord.find(filter).skip(skip).limit(limit),
            CensoRecord.countDocuments(filter),
        ]);

        res.status(200).json({
            success: true,
            data: records,
            pagination: getPaginationMeta(total, page, limit),
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncCensoRecord, getCensoRecords, updateCensoRecord, deleteCensoRecord };
