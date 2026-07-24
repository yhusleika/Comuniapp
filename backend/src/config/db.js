const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`Conectado a MongoDB Atlas exitosamente: ${conn.connection.host}`);

        // Seed default admin account if not existing
        try {
            const User = require('../models/user.model');
            const adminExists = await User.findOne({ username: 'admin' });
            if (!adminExists) {
                const salt = await bcrypt.genSalt(12);
                const passwordHash = await bcrypt.hash('admin', salt);
                const adminUser = new User({
                    id: 'usr_admin',
                    username: 'admin',
                    role: 'admin',
                    nombres: 'Administrador',
                    apellidos: 'Sistema',
                    email: 'admin@comuniapp.org',
                    passwordHash: passwordHash
                });
                await adminUser.save();
                console.log('Usuario default admin creado exitosamente en MongoDB');
            }
        } catch (seedErr) {
            console.error('Error seeding admin user:', seedErr.message);
        }
    } catch (error) {
        console.error(`Error al conectar a MongoDB Atlas: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;
