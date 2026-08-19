const Censo = require('../models/censo.model');
const CensoRecord = require('../models/censo_record.model');
const { createSyncController, createGetAllController, createUpdateController } = require('../utils/crudFactory');

const syncCenso = createSyncController(Censo);
const getCensos = createGetAllController(Censo, { searchFields: ['nombre', 'zona', 'responsable'] });
const updateCenso = createUpdateController(Censo);

const deleteCenso = async (req, res) => {
    try {
        const censoId = req.params.id;
        const censo = await Censo.findOneAndDelete({ id: censoId });
        if (!censo) return res.status(404).json({ success: false, message: "Censo no encontrado" });

        await CensoRecord.deleteMany({ censoId: censoId });

        res.status(200).json({ success: true, message: "Censo y sus registros asociados eliminados" });
    } catch (error) {
        console.error('Error eliminando censo:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { syncCenso, getCensos, updateCenso, deleteCenso };
