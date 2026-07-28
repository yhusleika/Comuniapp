const Ayuda = require('../models/ayuda.model');
const { createSyncController, createGetAllController, createUpdateController, createDeleteController } = require('../utils/crudFactory');

const syncAyuda = createSyncController(Ayuda, { deleteIsSynced: false });
const getAyudas = createGetAllController(Ayuda, { searchFields: ['nombre', 'responsable'] });
const updateAyuda = createUpdateController(Ayuda, { deleteIsSynced: false });
const deleteAyuda = createDeleteController(Ayuda);

module.exports = { syncAyuda, getAyudas, updateAyuda, deleteAyuda };
