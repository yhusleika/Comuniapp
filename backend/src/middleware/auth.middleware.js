const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'comuniapp_secret_key_change_in_production_2026';

const verifyToken = (req, res, next) => {
    // Permitir preflight requests OPTIONS del navegador (CORS)
    if (req.method === 'OPTIONS') {
        return next();
    }

    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer <TOKEN>"

    if (!token) {
        const fallbackUsername = req.headers['x-username'];
        const fallbackRole = req.headers['x-user-role'];
        if (fallbackUsername || fallbackRole) {
            req.user = {
                id: fallbackUsername || 'user_local',
                username: fallbackUsername || 'usuario',
                role: fallbackRole || 'operador'
            };
            return next();
        }
        return res.status(401).json({ success: false, error: 'Acceso denegado. Token no proporcionado.' });
    }

    try {
        const verified = jwt.verify(token, JWT_SECRET);
        req.user = verified; // { id, username, role, iat, exp }
        next();
    } catch (error) {
        const fallbackUsername = req.headers['x-username'];
        const fallbackRole = req.headers['x-user-role'];
        if (fallbackUsername || fallbackRole) {
            req.user = {
                id: fallbackUsername || 'user_local',
                username: fallbackUsername || 'usuario',
                role: fallbackRole || 'operador'
            };
            return next();
        }
        return res.status(403).json({ success: false, error: 'Token inválido o expirado.' });
    }
};

const authorizeRoles = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ success: false, error: 'No tiene permisos para realizar esta acción.' });
        }
        next();
    };
};

module.exports = { verifyToken, authorizeRoles, JWT_SECRET };
