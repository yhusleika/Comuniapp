const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    id: { type: String, required: true, unique: true },
    username: { type: String, required: true, unique: true },
    role: { type: String, required: true }, // 'admin' or 'vocero'
    nombres: { type: String, default: '' },
    apellidos: { type: String, default: '' },
    cedula: { type: String, default: '' },
    email: { type: String, default: '' },
    telefono: { type: String, default: '' },
    photoUrl: { type: String, default: '' },
    passwordHash: { type: String, default: '' }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
