const Habitante = require('../models/habitante.model');
const Reporte = require('../models/reporte.model');
const Censo = require('../models/censo.model');
const CensoRecord = require('../models/censo_record.model');
const Ayuda = require('../models/ayuda.model');
const Evento = require('../models/evento.model');

const getStats = async (req, res) => {
    try {
        const [habitants, reports, censos, censoRecords, ayudas, eventos] = await Promise.all([
            Habitante.countDocuments(),
            Reporte.countDocuments(),
            Censo.countDocuments(),
            CensoRecord.countDocuments(),
            Ayuda.countDocuments(),
            Evento.countDocuments(),
        ]);

        // Conteos por categoría de eventos
        const [eventosCount, proyectosCount, jornadasCount] = await Promise.all([
            Evento.countDocuments({ category: 'Eventos' }),
            Evento.countDocuments({ category: 'Proyectos' }),
            Evento.countDocuments({ category: 'Jornadas' }),
        ]);

        // Últimas 10 actividades (de todas las colecciones, ordenadas por fecha)
        const [recentHabitants, recentReports, recentEventos] = await Promise.all([
            Habitante.find().sort({ createdAt: -1 }).limit(5).select('id nombres apellidos createdAt'),
            Reporte.find().sort({ createdAt: -1 }).limit(5).select('id titulo tipo createdAt'),
            Evento.find().sort({ createdAt: -1 }).limit(5).select('id name category status createdAt'),
        ]);

        // Combinar y ordenar actividades recientes
        const recentActivity = [
            ...recentHabitants.map(h => ({
                type: 'habitante',
                title: `Nuevo habitante: ${h.nombres} ${h.apellidos}`,
                date: h.createdAt,
            })),
            ...recentReports.map(r => ({
                type: 'reporte',
                title: `Reporte: ${r.titulo}`,
                subtitle: r.tipo,
                date: r.createdAt,
            })),
            ...recentEventos.map(e => ({
                type: 'evento',
                title: `${e.category}: ${e.name}`,
                subtitle: e.status,
                date: e.createdAt,
            })),
        ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 10);

        res.status(200).json({
            success: true,
            data: {
                counts: {
                    habitants,
                    reports,
                    censos,
                    censoRecords,
                    ayudas,
                    eventos: eventos,
                    eventosCategory: eventosCount,
                    proyectos: proyectosCount,
                    jornadas: jornadasCount,
                },
                recentActivity,
            }
        });
    } catch (error) {
        console.error('Error obteniendo stats:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getStats };
