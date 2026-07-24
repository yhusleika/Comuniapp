const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth.middleware');

// Registro de nuevos usuarios con contraseña hasheada
const register = async (req, res) => {
    try {
        const { username, password, role, nombres, apellidos, cedula, email, telefono } = req.body;

        if (!username || !password) {
            return res.status(400).json({ success: false, error: 'Usuario y contraseña son requeridos' });
        }

        const existingUser = await User.findOne({ username: username });
        if (existingUser) {
            return res.status(400).json({ success: false, error: 'El nombre de usuario ya está registrado' });
        }

        // Hashing seguro de contraseña con bcrypt
        const salt = await bcrypt.genSalt(12);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = new User({
            id: `usr_${Date.now()}`,
            username,
            role: role || 'vocero',
            nombres: nombres || '',
            apellidos: apellidos || '',
            cedula: cedula || '',
            email: email || '',
            telefono: telefono || '',
            passwordHash: hashedPassword
        });

        await newUser.save();

        // Emitir Token JWT
        const token = jwt.sign(
            { id: newUser.id, username: newUser.username, role: newUser.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            success: true,
            message: 'Usuario registrado exitosamente',
            token,
            data: {
                id: newUser.id,
                username: newUser.username,
                role: newUser.role,
                nombres: newUser.nombres,
                apellidos: newUser.apellidos,
                email: newUser.email
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Login de usuario con verificación estricta de hash en MongoDB y emisión de JWT
const login = async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({ success: false, error: 'Usuario y contraseña son requeridos' });
        }

        const cleanUsername = username.trim().toLowerCase();
        const cleanPassword = password.trim();

        // Buscar usuario estrictamente en la base de datos MongoDB
        const user = await User.findOne({ username: cleanUsername });

        if (!user) {
            return res.status(401).json({ success: false, error: 'Usuario o contraseña incorrectos' });
        }

        // Verificar la contraseña usando bcrypt
        let validPassword = await bcrypt.compare(cleanPassword, user.passwordHash);

        // Si la contraseña guardada era en texto plano (migración legacy), verificar y actualizar a hash bcrypt
        if (!validPassword && user.passwordHash === cleanPassword) {
            const salt = await bcrypt.genSalt(12);
            user.passwordHash = await bcrypt.hash(cleanPassword, salt);
            await user.save();
            validPassword = true;
        }

        if (!validPassword) {
            return res.status(401).json({ success: false, error: 'Usuario o contraseña incorrectos' });
        }

        // Generar Token JWT
        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(200).json({
            success: true,
            message: 'Inicio de sesión exitoso',
            token,
            data: {
                id: user.id,
                username: user.username,
                role: user.role,
                nombres: user.nombres,
                apellidos: user.apellidos,
                email: user.email,
                photoUrl: user.photoUrl
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { register, login };
