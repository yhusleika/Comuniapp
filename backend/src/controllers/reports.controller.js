const Reporte = require('../models/reporte.model');
const { createSyncController, createGetAllController, createUpdateController, createDeleteController } = require('../utils/crudFactory');

const syncReporte = createSyncController(Reporte);
const getReportes = createGetAllController(Reporte, { searchFields: ['titulo', 'tipo'] });
const updateReporte = createUpdateController(Reporte);
const deleteReporte = createDeleteController(Reporte);

module.exports = { syncReporte, getReportes, updateReporte, deleteReporte };
