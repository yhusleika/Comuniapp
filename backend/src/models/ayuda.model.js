const mongoose = require('mongoose');

const ayudaSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    nombre: { type: String, required: true },
    responsable: { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model('Ayuda', ayudaSchema);
