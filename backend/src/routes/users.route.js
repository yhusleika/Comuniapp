const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { getUsers, createUser, updateUser, deleteUser, updateProfile, getProfile, resetPasswordPublic } = require('../controllers/users.controller');
const { register, login } = require('../controllers/auth.controller');
const { verifyToken } = require('../middleware/auth.middleware');

// Asegurar que existe la carpeta uploads
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuración de almacenamiento de Multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// Rutas públicas de autenticación
router.post('/register', register);
router.post('/login', login);
router.post('/reset-password', resetPasswordPublic);

// Rutas CRUD de gestión de usuarios (Admin/Backend)
router.get('/', verifyToken, getUsers);
router.post('/', verifyToken, createUser);
router.put('/profile', verifyToken, upload.single('photo'), updateProfile);
router.put('/:username', verifyToken, updateUser);
router.delete('/:username', verifyToken, deleteUser);
router.get('/profile/:username', verifyToken, getProfile);

module.exports = router;
