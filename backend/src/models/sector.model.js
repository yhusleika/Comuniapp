const mongoose = require('mongoose');

const sectorSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    nombre: { type: String, required: true },
    descripcion: { type: String, default: '' },
    totalHabitantes: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('Sector', sectorSchema);
