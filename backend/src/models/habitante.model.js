const mongoose = require('mongoose');

const habitanteSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true }, // Usaremos el ID generado localmente en Hive
    cedula: { type: String, required: true },
    nombres: { type: String, required: true },
    apellidos: { type: String, required: true },
    telefono: { type: String, required: true },
    sector: { type: String, required: true },
    puntoReferencia: { type: String },
    tieneDiscapacidad: { type: Boolean, default: false },
    detallesDiscapacidad: { type: String, default: '' },
    tieneEnfermedadCronica: { type: Boolean, default: false },
    detallesEnfermedad: { type: String, default: '' },
    condicionVivienda: { type: String, required: true },
    tipoVivienda: { type: String, required: true },
    registeredBy: { type: String, required: true },
    fechaRegistro: { type: Date, required: true },
    fechaNacimiento: { type: Date },
    ayudaRecibida: { type: String, default: '' }
}, {
    timestamps: true
});

module.exports = mongoose.model('Habitante', habitanteSchema);
