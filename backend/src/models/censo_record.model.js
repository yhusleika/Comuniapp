const mongoose = require('mongoose');

const censoRecordSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    censoId: { type: String, required: true },
    jefeFamilia: { type: String, required: true },
    cedula: { type: String, required: true },
    direccion: { type: String, required: true },
    numeroHijos: { type: Number, required: true },
    estatus: { type: String, required: true },
    // datosDinamicos es un mapa libre (los campos del censo son configurables)
    datosDinamicos: { type: mongoose.Schema.Types.Mixed, default: {} }
}, {
    timestamps: true
});

module.exports = mongoose.model('CensoRecord', censoRecordSchema);
