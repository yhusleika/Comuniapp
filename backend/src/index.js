const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

// Cargar variables de entorno
dotenv.config();

// Conectar a la base de datos
connectDB();

const app = express();

// 1. Control de CORS con soporte preflight para Flutter Web y móvil
app.use(cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'x-user-role', 'x-username', 'X-User-Role', 'X-Username']
}));

// 2. Cabeceras HTTP de Seguridad (Helmet)
app.use(helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// 3. Rate Limiting (Prevención de ataques de Fuerza Bruta y DoS)
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 200, // Máximo 200 peticiones por ventana por IP
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: 'Demasiadas solicitudes desde esta IP. Por favor intente más tarde.' }
});
app.use('/v1/', apiLimiter);

// 4. Middlewares de datos y Sanitización NoSQL
app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
    if (req.body) req.body = mongoSanitize.sanitize(req.body);
    if (req.params) req.params = mongoSanitize.sanitize(req.params);
    next();
});

// Log de peticiones (útil para depurar en producción)
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

// Importar middleware de autenticación
const { verifyToken } = require('./middleware/auth.middleware');

// Rutas públicas de usuarios (Login / Register) y protegidas de perfil
app.use('/v1/users', require('./routes/users.route'));

// Rutas protegidas por JWT
app.use('/v1/habitants', verifyToken, require('./routes/habitants.route'));
app.use('/v1/reports', verifyToken, require('./routes/reports.route'));
app.use('/v1/censos', verifyToken, require('./routes/censos.route'));
app.use('/v1/censo_records', verifyToken, require('./routes/censo_records.route'));
app.use('/v1/ayudas', verifyToken, require('./routes/ayudas.route'));
app.use('/v1/eventos', verifyToken, require('./routes/eventos.route'));
app.use('/v1/stats', verifyToken, require('./routes/stats.route'));
app.use('/v1/auditoria', verifyToken, require('./routes/auditoria.route'));
app.use('/v1/sectores', verifyToken, require('./routes/sectores.route'));

// Servir archivos estáticos de uploads
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Ruta base para comprobar que la API funciona
app.get('/', (req, res) => {
    res.json({ message: 'Bienvenido a la API de Comuniapp - Servidor Seguro' });
});

// Health check para Render y monitoreo
app.get(['/health', '/v1/health'], (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor seguro corriendo en el puerto ${PORT} (0.0.0.0)`);
});

