const Habitante = require('../models/habitante.model');
const Reporte = require('../models/reporte.model');
const Censo = require('../models/censo.model');
const CensoRecord = require('../models/censo_record.model');
const Ayuda = require('../models/ayuda.model');
const Evento = require('../models/evento.model');

const getStats = async (req, res) => {
    try {
        const [countsResult, ageBuckets, eventosCategoryCount, recentActivity] = await Promise.all([
            Promise.all([
                Habitante.countDocuments(),
                Reporte.countDocuments(),
                Censo.countDocuments(),
                CensoRecord.countDocuments(),
                Ayuda.countDocuments(),
                Evento.countDocuments(),
            ]),
            Habitante.aggregate([
                {
                    $bucket: {
                        groupBy: { $ifNull: ['$edad', null] },
                        boundaries: [0, 15, 30, 60, 150],
                        default: 'unknown',
                        output: { count: { $sum: 1 } }
                    }
                }
            ]),
            Evento.aggregate([
                { $group: { _id: '$category', count: { $sum: 1 } } }
            ]),
            Promise.all([
                Habitante.find().sort({ createdAt: -1 }).limit(5).select('id nombres apellidos createdAt'),
                Reporte.find().sort({ createdAt: -1 }).limit(5).select('id titulo tipo createdAt'),
                Evento.find().sort({ createdAt: -1 }).limit(5).select('id name category status createdAt'),
            ]),
        ]);

        const [habitantsCount, reportsCount, censosCount, censoRecordsCount, ayudasCount, eventosCount] = countsResult;

        const ageDistribution = { children: 0, youth: 0, adults: 0, seniors: 0 };
        for (const bucket of ageBuckets) {
            if (bucket._id === 0) ageDistribution.children = bucket.count;
            else if (bucket._id === 15) ageDistribution.youth = bucket.count;
            else if (bucket._id === 30) ageDistribution.adults = bucket.count;
            else if (bucket._id === 60) ageDistribution.seniors = bucket.count;
        }

        const categoryCounts = { Eventos: 0, Proyectos: 0, Jornadas: 0 };
        for (const cat of eventosCategoryCount) {
            if (cat._id in categoryCounts) categoryCounts[cat._id] = cat.count;
        }

        const [recentHabitants, recentReports, recentEventos] = recentActivity;
        const recentActivityList = [
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

        const totalAge = ageDistribution.children + ageDistribution.youth + ageDistribution.adults + ageDistribution.seniors;

        res.status(200).json({
            success: true,
            data: {
                counts: {
                    habitants: habitantsCount,
                    reports: reportsCount,
                    censos: censosCount,
                    censoRecords: censoRecordsCount,
                    ayudas: ayudasCount,
                    eventos: eventosCount,
                    eventosCategory: categoryCounts.Eventos,
                    proyectos: categoryCounts.Proyectos,
                    jornadas: categoryCounts.Jornadas,
                },
                demographics: {
                    totalHabitants: habitantsCount,
                    ageDistribution: {
                        children: ageDistribution.children,
                        youth: ageDistribution.youth,
                        adults: ageDistribution.adults,
                        seniors: ageDistribution.seniors,
                        childrenPct: totalAge > 0 ? Number(((ageDistribution.children / totalAge) * 100).toFixed(1)) : 0,
                        youthPct: totalAge > 0 ? Number(((ageDistribution.youth / totalAge) * 100).toFixed(1)) : 0,
                        adultsPct: totalAge > 0 ? Number(((ageDistribution.adults / totalAge) * 100).toFixed(1)) : 0,
                        seniorsPct: totalAge > 0 ? Number(((ageDistribution.seniors / totalAge) * 100).toFixed(1)) : 0,
                    },
                },
                recentActivity: recentActivityList,
            }
        });
    } catch (error) {
        console.error('Error obteniendo stats:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getStats };
