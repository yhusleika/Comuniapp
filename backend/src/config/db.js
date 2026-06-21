const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        // Obtenemos la URI de las variables de entorno
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`Conectado a MongoDB Atlas exitosamente: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error al conectar a MongoDB Atlas: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;
