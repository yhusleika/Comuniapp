const mongoose = require('mongoose');

const auditoriaSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    user: { type: String, required: true },
    role: { type: String, required: true },
    action: { type: String, required: true },
    dateTime: { type: Date, required: true },
}, { timestamps: true });

module.exports = mongoose.model('Auditoria', auditoriaSchema);
