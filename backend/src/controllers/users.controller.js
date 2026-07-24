const User = require('../models/user.model');
const bcrypt = require('bcryptjs');

// Obtener todos los usuarios
const getUsers = async (req, res) => {
    try {
        const users = await User.find().select('-passwordHash');
        res.status(200).json({ success: true, data: users });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Crear usuario (Admin)
const createUser = async (req, res) => {
    try {
        const { username, password, role, nombres, apellidos, email, cedula, telefono } = req.body;
        if (!username || !password) {
            return res.status(400).json({ success: false, error: 'Usuario y contraseña son requeridos' });
        }

        const existing = await User.findOne({ username: username.toLowerCase().trim() });
        if (existing) {
            return res.status(400).json({ success: false, error: 'El nombre de usuario ya está registrado' });
        }

        const salt = await bcrypt.genSalt(12);
        const passwordHash = await bcrypt.hash(password, salt);

        const newUser = new User({
            id: `usr_${Date.now()}`,
            username: username.toLowerCase().trim(),
            passwordHash,
            role: role || 'operador',
            nombres: nombres || '',
            apellidos: apellidos || '',
            email: email || '',
            cedula: cedula || '',
            telefono: telefono || '',
        });

        await newUser.save();
        res.status(201).json({ success: true, message: 'Usuario creado exitosamente', data: newUser });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Actualizar usuario por username o ID
const updateUser = async (req, res) => {
    try {
        const { username } = req.params;
        const updateData = { ...req.body };

        if (updateData.password) {
            const salt = await bcrypt.genSalt(12);
            updateData.passwordHash = await bcrypt.hash(updateData.password, salt);
            delete updateData.password;
        }

        const user = await User.findOneAndUpdate(
            { username: username },
            { $set: updateData },
            { new: true }
        ).select('-passwordHash');

        if (!user) {
            return res.status(404).json({ success: false, error: 'Usuario no encontrado' });
        }

        res.status(200).json({ success: true, message: 'Usuario actualizado exitosamente', data: user });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Eliminar usuario
const deleteUser = async (req, res) => {
    try {
        const { username } = req.params;
        const deleted = await User.findOneAndDelete({ username: username });
        if (!deleted) {
            return res.status(404).json({ success: false, error: 'Usuario no encontrado' });
        }
        res.status(200).json({ success: true, message: 'Usuario eliminado exitosamente' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Actualizar o crear perfil de usuario propio
const updateProfile = async (req, res) => {
    try {
        const username = req.user ? req.user.username : (req.headers['x-username'] || req.body.username);
        if (!username) {
            return res.status(400).json({ success: false, error: 'Usuario no autenticado o especificado' });
        }

        const updateData = {
            nombres: req.body.nombres,
            apellidos: req.body.apellidos,
            cedula: req.body.cedula,
            email: req.body.email,
            telefono: req.body.telefono,
        };

        if (req.body.password) {
            const salt = await bcrypt.genSalt(12);
            updateData.passwordHash = await bcrypt.hash(req.body.password, salt);
        }

        if (req.file) {
            updateData.photoUrl = `/uploads/${req.file.filename}`;
        }

        const user = await User.findOneAndUpdate(
            { username: username },
            { $set: updateData },
            { new: true, upsert: true }
        );

        res.status(200).json({ success: true, message: 'Perfil actualizado exitosamente', data: user });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Obtener perfil de usuario
const getProfile = async (req, res) => {
    try {
        const username = req.params.username || (req.user ? req.user.username : req.headers['x-username']);
        if (!username) {
            return res.status(400).json({ success: false, error: 'Usuario no especificado' });
        }

        const user = await User.findOne({ username: username });
        if (!user) {
            return res.status(200).json({
                success: true,
                data: {
                    username: username,
                    role: username.includes('admin') ? 'admin' : 'operador',
                    nombres: '',
                    apellidos: '',
                    cedula: '',
                    email: '',
                    telefono: '',
                    photoUrl: ''
                }
            });
        }

        res.status(200).json({ success: true, data: user });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getUsers, createUser, updateUser, deleteUser, updateProfile, getProfile };
