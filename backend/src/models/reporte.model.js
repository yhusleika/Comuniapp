const mongoose = require('mongoose');

const reporteSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    titulo: { type: String, required: true },
    descripcion: { type: String, required: true },
    tipo: { type: String, required: true },
    prioridad: { type: String, required: true },
    estatus: { type: String, required: true },
    fotosPaths: { type: [String], default: [] },
    latitud: { type: Number, required: true },
    longitud: { type: Number, required: true },
    createdBy: { type: String, required: true },
    fechaRegistro: { type: Date, required: true }
}, {
    timestamps: true
});

module.exports = mongoose.model('Reporte', reporteSchema);
