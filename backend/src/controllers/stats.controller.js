const Habitante = require('../models/habitante.model');
const Reporte = require('../models/reporte.model');
const Censo = require('../models/censo.model');
const CensoRecord = require('../models/censo_record.model');
const Ayuda = require('../models/ayuda.model');
const Evento = require('../models/evento.model');

const calculateAge = (birthDate) => {
    if (!birthDate) return null;
    const today = new Date();
    const birth = new Date(birthDate);
    if (isNaN(birth.getTime())) return null;
    let age = today.getFullYear() - birth.getFullYear();
    const m = today.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
        age--;
    }
    return age;
};

const isFemaleName = (name) => {
    if (!name) return false;
    const clean = name.trim().split(' ')[0].toLowerCase();
    return clean.endsWith('a') || clean.endsWith('is') || clean.endsWith('en') || clean.endsWith('ly') || clean.endsWith('i');
};

const getStats = async (req, res) => {
    try {
        const [allHabitants, reportsCount, censosCount, allCensoRecords, ayudasCount, eventosCount] = await Promise.all([
            Habitante.find(),
            Reporte.countDocuments(),
            Censo.countDocuments(),
            CensoRecord.find(),
            Ayuda.countDocuments(),
            Evento.countDocuments(),
        ]);

        const habitantsCount = allHabitants.length;
        const censoRecordsCount = allCensoRecords.length;

        // Conteos por categoría de eventos
        const [eventosCategoryCount, proyectosCount, jornadasCount] = await Promise.all([
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

        // Agregaciones Demográficas Reales
        let children = 0, youth = 0, adults = 0, seniors = 0;
        let femaleCount = 0, maleCount = 0;
        let eduCounts = { Analfabeta: 0, Primaria: 0, Secundaria: 0, Técnica: 0, Universitaria: 0, Otro: 0 };
        let volNinguna = 0, volMotora = 0, volVisual = 0, volAuditiva = 0, volIntelectual = 0;

        const processAge = (age) => {
            if (age === null || isNaN(age)) return;
            if (age < 15) children++;
            else if (age < 30) youth++;
            else if (age < 60) adults++;
            else seniors++;
        };

        const countedHabitanteIds = new Set();

        for (const h of allHabitants) {
            if (h.id) countedHabitanteIds.add(h.id.toString());
            if (isFemaleName(h.nombres)) femaleCount++;
            else maleCount++;

            if (h.fechaNacimiento) {
                processAge(calculateAge(h.fechaNacimiento));
            }

            if (h.tieneDiscapacidad) {
                const desc = (h.detallesDiscapacidad || '').toLowerCase();
                if (desc.includes('motor') || desc.includes('fisic')) volMotora++;
                else if (desc.includes('visual') || desc.includes('cieg') || desc.includes('vista')) volVisual++;
                else if (desc.includes('audit') || desc.includes('sord')) volAuditiva++;
                else if (desc.includes('intel') || desc.includes('ment') || desc.includes('cognit')) volIntelectual++;
                else volMotora++;
            } else {
                volNinguna++;
            }
        }

        for (const cr of allCensoRecords) {
            const recordData = cr.datosDinamicos || {};
            const familiares = Array.isArray(recordData.familiares) ? recordData.familiares : [];

            for (const m of familiares) {
                if (typeof m !== 'object' || !m) continue;
                const habitanteId = m.habitanteId ? m.habitanteId.toString() : '';
                const isLinked = habitanteId && countedHabitanteIds.has(habitanteId);

                const name = m.jefeFamilia || m.nombres || '';
                const edu = m.escolaridad || '';

                if (name && !isLinked) {
                    if (isFemaleName(name)) femaleCount++;
                    else maleCount++;
                }

                if (m.edad) {
                    const age = parseInt(m.edad, 10);
                    if (!isNaN(age)) processAge(age);
                }

                if (edu) {
                    const matchedKey = Object.keys(eduCounts).find(k => edu.toLowerCase().includes(k.toLowerCase())) || 'Otro';
                    eduCounts[matchedKey]++;
                }

                if (!isLinked) {
                    const discList = m.salud_discapacidad;
                    if (discList) {
                        const str = discList.toString().toLowerCase();
                        if (str.includes('ninguna') || !str) volNinguna++;
                        else {
                            if (str.includes('motor')) volMotora++;
                            if (str.includes('visual')) volVisual++;
                            if (str.includes('audit')) volAuditiva++;
                            if (str.includes('intel')) volIntelectual++;
                        }
                    } else {
                        volNinguna++;
                    }
                }
            }
        }

        const totalGender = femaleCount + maleCount;
        const totalAge = children + youth + adults + seniors;
        const totalEdu = Object.values(eduCounts).reduce((a, b) => a + b, 0);
        const totalVol = volNinguna + volMotora + volVisual + volAuditiva + volIntelectual;
        const vulnPct = totalVol > 0 ? ((volMotora + volVisual + volAuditiva + volIntelectual) / totalVol) * 100 : 0;

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
                    eventosCategory: eventosCategoryCount,
                    proyectos: proyectosCount,
                    jornadas: jornadasCount,
                },
                demographics: {
                    totalHabitants: habitantsCount,
                    totalGender,
                    femaleCount,
                    maleCount,
                    femalePercentage: totalGender > 0 ? Number(((femaleCount / totalGender) * 100).toFixed(1)) : 0,
                    malePercentage: totalGender > 0 ? Number(((maleCount / totalGender) * 100).toFixed(1)) : 0,
                    ageDistribution: {
                        children,
                        youth,
                        adults,
                        seniors,
                        childrenPct: totalAge > 0 ? Number(((children / totalAge) * 100).toFixed(1)) : 0,
                        youthPct: totalAge > 0 ? Number(((youth / totalAge) * 100).toFixed(1)) : 0,
                        adultsPct: totalAge > 0 ? Number(((adults / totalAge) * 100).toFixed(1)) : 0,
                        seniorsPct: totalAge > 0 ? Number(((seniors / totalAge) * 100).toFixed(1)) : 0,
                    },
                    educationLevels: eduCounts,
                    totalEdu,
                    vulnerabilityRate: Number(vulnPct.toFixed(1)),
                    vulnerability: {
                        ninguna: volNinguna,
                        motora: volMotora,
                        visual: volVisual,
                        auditiva: volAuditiva,
                        intelectual: volIntelectual,
                        ningunaPct: totalVol > 0 ? Number(((volNinguna / totalVol) * 100).toFixed(1)) : 0,
                        motoraPct: totalVol > 0 ? Number(((volMotora / totalVol) * 100).toFixed(1)) : 0,
                        visualPct: totalVol > 0 ? Number(((volVisual / totalVol) * 100).toFixed(1)) : 0,
                        auditivaPct: totalVol > 0 ? Number(((volAuditiva / totalVol) * 100).toFixed(1)) : 0,
                        intelectualPct: totalVol > 0 ? Number(((volIntelectual / totalVol) * 100).toFixed(1)) : 0,
                    }
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

