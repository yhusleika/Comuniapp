/**
 * Role-based authorization middleware.
 * Checks the 'x-user-role' header against the list of allowed roles.
 *
 * Usage in routes:
 *   const { requireRole } = require('../middleware/role.middleware');
 *   router.delete('/:id', requireRole('admin'), deleteController);
 */

const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        const userRole = req.headers['x-user-role'];

        if (!userRole) {
            return res.status(401).json({
                success: false,
                error: 'No se encontró el rol del usuario. Encabezado x-user-role requerido.',
            });
        }

        if (!allowedRoles.includes(userRole)) {
            return res.status(403).json({
                success: false,
                error: `Acceso denegado. Se requiere rol: ${allowedRoles.join(' o ')}`,
            });
        }

        next();
    };
};

module.exports = { requireRole };
