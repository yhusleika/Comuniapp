const mongoose = require('mongoose');

const eventoSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    date: { type: Date, required: true },
    description: { type: String, default: '' },
    responsible: { type: String, required: true },
    category: { type: String, required: true }, // 'Eventos', 'Proyectos', 'Jornadas'
    progress: { type: Number, default: 0.0 },
    status: { type: String, default: 'Pendiente' },
    attendeeNames: { type: [String], default: [] },
    photos: { type: [String], default: [] },
    avances: [{
        descripcion: { type: String, required: true },
        fecha: { type: Date, default: Date.now },
        fotos: { type: [String], default: [] },
        progress: { type: Number, default: 0.0 }
    }]
}, { timestamps: true });

module.exports = mongoose.model('Evento', eventoSchema);
