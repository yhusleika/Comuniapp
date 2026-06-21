const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

// Cargar variables de entorno
dotenv.config();

// Conectar a la base de datos
connectDB();

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Rutas
app.use('/v1/habitants', require('./routes/habitants.route'));
app.use('/v1/reports', require('./routes/reports.route'));
app.use('/v1/censos', require('./routes/censos.route'));
app.use('/v1/censo_records', require('./routes/censo_records.route'));
app.use('/v1/ayudas', require('./routes/ayudas.route'));
app.use('/v1/eventos', require('./routes/eventos.route'));
app.use('/v1/stats', require('./routes/stats.route'));

// Ruta base para comprobar que la API funciona
app.get('/', (req, res) => {
    res.json({ message: 'Bienvenido a la API de Comuniapp' });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Servidor corriendo en el puerto ${PORT}`);
});
