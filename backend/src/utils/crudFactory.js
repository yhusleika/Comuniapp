const { getPagination, getPaginationMeta } = require('./pagination');

const createSyncController = (Model, options = {}) => {
    const { idField = 'id', deleteIsSynced = true } = options;

    return async (req, res) => {
        try {
            const data = { ...req.body };
            if (deleteIsSynced) {
                delete data.isSynced;
            }
            const doc = await Model.findOneAndUpdate(
                { [idField]: data[idField] },
                data,
                { new: true, upsert: true }
            );
            res.status(200).json({ success: true, message: `${Model.modelName} sincronizado`, data: doc });
        } catch (error) {
            console.error(`Error sync ${Model.modelName}:`, error);
            res.status(500).json({ success: false, error: error.message });
        }
    };
};

const createGetAllController = (Model, options = {}) => {
    const { searchFields = [], select } = options;

    return async (req, res) => {
        try {
            const { page, limit, skip } = getPagination(req.query);
            const { search } = req.query;

            let query = {};
            if (search && search.trim().length > 0) {
                const searchString = search.trim();
                if (searchFields.length > 0) {
                    query.$or = searchFields.map(field => ({
                        [field]: { $regex: searchString, $options: 'i' }
                    }));
                }
            }

            const [docs, total] = await Promise.all([
                Model.find(query).skip(skip).limit(limit).select(select || ''),
                Model.countDocuments(query),
            ]);

            res.status(200).json({
                success: true,
                data: docs,
                pagination: getPaginationMeta(total, page, limit),
            });
        } catch (error) {
            console.error(`Error get ${Model.modelName}:`, error);
            res.status(500).json({ success: false, error: error.message });
        }
    };
};

const createUpdateController = (Model, options = {}) => {
    const { idField = 'id', deleteIsSynced = true } = options;

    return async (req, res) => {
        try {
            const data = { ...req.body };
            if (deleteIsSynced) {
                delete data.isSynced;
            }
            const doc = await Model.findOneAndUpdate(
                { [idField]: req.params.id },
                data,
                { new: true }
            );

            if (!doc) {
                return res.status(404).json({ success: false, error: `${Model.modelName} no encontrado` });
            }

            res.status(200).json({ success: true, message: `${Model.modelName} actualizado`, data: doc });
        } catch (error) {
            console.error(`Error update ${Model.modelName}:`, error);
            res.status(500).json({ success: false, error: error.message });
        }
    };
};

const createDeleteController = (Model, options = {}) => {
    const { idField = 'id' } = options;

    return async (req, res) => {
        try {
            const doc = await Model.findOneAndDelete({ [idField]: req.params.id });

            if (!doc) {
                return res.status(404).json({ success: false, error: `${Model.modelName} no encontrado` });
            }

            res.status(200).json({ success: true, message: `${Model.modelName} eliminado` });
        } catch (error) {
            console.error(`Error delete ${Model.modelName}:`, error);
            res.status(500).json({ success: false, error: error.message });
        }
    };
};

module.exports = { createSyncController, createGetAllController, createUpdateController, createDeleteController };
