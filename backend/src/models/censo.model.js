const mongoose = require('mongoose');

const censoSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    nombre: { type: String, required: true },
    zona: { type: String, required: true },
    responsable: { type: String, required: true },
    fecha: { type: Date, required: true },
    camposSeleccionados: { type: [String], default: [] }
}, {
    timestamps: true
});

module.exports = mongoose.model('Censo', censoSchema);
