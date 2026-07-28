import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../../core/services/hive_config.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../habitantes/data/models/habitante_model.dart';
import '../../../censos/data/models/censo_record_model.dart';
import '../../../censos/presentation/bloc/censos_bloc.dart';
import '../../../censos/presentation/bloc/censos_event.dart';
import '../../../censos/presentation/bloc/censos_state.dart';
import '../../../habitantes/presentation/bloc/habitants_bloc.dart';

class EstadisticasPage extends StatelessWidget {
  const EstadisticasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CensosBloc>()..add(LoadCensos())),
        BlocProvider(create: (_) => sl<HabitantsBloc>()..add(const LoadHabitants())),
      ],
      child: const EstadisticasView(),
    );
  }
}

class EstadisticasView extends StatefulWidget {
  const EstadisticasView({super.key});

  @override
  State<EstadisticasView> createState() => _EstadisticasViewState();
}

class _EstadisticasViewState extends State<EstadisticasView>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  String _selectedPeriod = 'Este Mes';
  final List<String> _periods = ['Esta Semana', 'Este Mes', 'Este Año'];

  bool _isChatOpen = false;
  final List<_ChatMessage> _chatMessages = [];
  final _chatInputController = TextEditingController();

  // ── Dynamic data for the Premium Dashboard ─────────────────────────────────
  int _totalInhabitants = 0;
  double _vulnerabilityRate = 0.0;
  int _totalCensos = 0;
  int _totalAyudas = 0;
  List<_DemographicItem> _ageDistribution = [];
  double _femalePercentage = 0.0;
  double _malePercentage = 0.0;
  List<_DemographicItem> _educationLevels = [];
  List<_DonutSlice> _vulnerabilityData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _loadAndAggregateData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final month1 = today.month;
    final month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      final day1 = today.day;
      final day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  Future<void> _loadAndAggregateData() async {
    try {
      final mongoService = sl<MongoDBService>();
      
      Map<String, dynamic> remoteStats = {};
      List<dynamic> remoteHabitants = [];
      List<dynamic> remoteCensoRecords = [];
      bool isRemoteConnected = false;

      try {
        remoteStats = await mongoService.getStats();
        remoteHabitants = await mongoService.getRecords('habitants');
        remoteCensoRecords = await mongoService.getRecords('censo_records');
        isRemoteConnected = true;
      } catch (_) {}

      final habitantsBox = Hive.isBoxOpen(HiveConfig.habitantsBox)
          ? Hive.box(HiveConfig.habitantsBox)
          : await Hive.openBox(HiveConfig.habitantsBox);
          
      final censoRecordsBox = Hive.isBoxOpen(HiveConfig.censoRecordsBox)
          ? Hive.box(HiveConfig.censoRecordsBox)
          : await Hive.openBox(HiveConfig.censoRecordsBox);

      final censosBox = Hive.isBoxOpen(HiveConfig.censosBox)
          ? Hive.box(HiveConfig.censosBox)
          : await Hive.openBox(HiveConfig.censosBox);

      if (isRemoteConnected) {
        // Sincronizar las cajas de Hive para eliminar registros locales fantasmas (ghost records) desincronizados
        final remoteHabitantIds = remoteHabitants.map((r) => (r['id'] ?? r['_id'] ?? '').toString()).toSet();
        final localHabitantesKeys = habitantsBox.keys.toList();
        for (final k in localHabitantesKeys) {
          final h = habitantsBox.get(k);
          if (h is HabitanteModel && !remoteHabitantIds.contains(h.id)) {
            await habitantsBox.delete(k);
          }
        }

        final remoteCensoRecordIds = remoteCensoRecords.map((r) => (r['id'] ?? r['_id'] ?? '').toString()).toSet();
        final localCensoRecordKeys = censoRecordsBox.keys.toList();
        for (final k in localCensoRecordKeys) {
          final r = censoRecordsBox.get(k);
          if (r is CensoRecordModel && !remoteCensoRecordIds.contains(r.id)) {
            await censoRecordsBox.delete(k);
          }
        }
      }

      final List<Map<String, dynamic>> allHabitants = [];
      final Set<String> countedHabitanteIds = {};

      if (isRemoteConnected) {
        for (final r in remoteHabitants) {
          final id = r['id']?.toString() ?? r['_id']?.toString() ?? '';
          if (id.isNotEmpty) {
            DateTime? birthDate;
            if (r['fechaNacimiento'] != null) {
              birthDate = DateTime.tryParse(r['fechaNacimiento'].toString());
            }
            allHabitants.add({
              'id': id,
              'nombres': r['nombres'] ?? '',
              'apellidos': r['apellidos'] ?? '',
              'cedula': r['cedula'] ?? '',
              'genero': r['genero'] ?? '',
              'fechaNacimiento': birthDate,
              'ayudaRecibida': r['ayudaRecibida'] ?? '',
              'tieneDiscapacidad': r['tieneDiscapacidad'] == true,
              'detallesDiscapacidad': r['detallesDiscapacidad'] ?? '',
            });
          }
        }
      } else {
        final localHabitants = habitantsBox.values.cast<HabitanteModel>().toList();
        for (final h in localHabitants) {
          allHabitants.add({
            'id': h.id,
            'nombres': h.nombres,
            'apellidos': h.apellidos,
            'cedula': h.cedula,
            'genero': h.genero,
            'fechaNacimiento': h.fechaNacimiento,
            'ayudaRecibida': h.ayudaRecibida,
            'tieneDiscapacidad': h.tieneDiscapacidad,
            'detallesDiscapacidad': h.detallesDiscapacidad,
          });
        }
      }

      int total = isRemoteConnected
          ? math.max(allHabitants.length, (remoteStats['counts']?['habitants'] as int?) ?? 0)
          : habitantsBox.length;

      int totalCensosCount = isRemoteConnected
          ? ((remoteStats['counts']?['censos'] as int?) ?? censosBox.length)
          : censosBox.length;
      final int remoteAyudasCount = (remoteStats['counts']?['ayudas'] as int?) ?? 0;
      int assignedAyudasCount = isRemoteConnected ? remoteAyudasCount : 0;
      int children = 0; // 0-14
      int youth = 0;    // 15-29
      int adults = 0;   // 30-59
      int seniors = 0;  // 60+

      int femaleCount = 0;
      int maleCount = 0;

      Map<String, int> eduCounts = {
        'Analfabeta': 0,
        'Primaria': 0,
        'Secundaria': 0,
        'Técnica': 0,
        'Universitaria': 0,
        'Otro': 0,
      };

      int volNinguna = 0;
      int volMotora = 0;
      int volVisual = 0;
      int volAuditiva = 0;
      int volIntelectual = 0;

      void processAge(int age) {
        if (age < 15) {
          children++;
        } else if (age < 30) {
          youth++;
        } else if (age < 60) {
          adults++;
        } else {
          seniors++;
        }
      }

      bool isFemale(String name, [String? explicitGender]) {
        if (explicitGender != null && explicitGender.trim().isNotEmpty) {
          final g = explicitGender.trim().toLowerCase();
          if (g == 'mujer' || g == 'femenino' || g == 'f') return true;
          if (g == 'hombre' || g == 'masculino' || g == 'm') return false;
        }
        final clean = name.trim().split(' ').first.toLowerCase();
        return clean.endsWith('a') || clean.endsWith('is') || clean.endsWith('en') || clean.endsWith('ly') || clean.endsWith('i');
      }

      // Buscar datos de escolaridad en registros de censos que estén enlazados a los habitantes registrados
      final List<dynamic> allCensoRecords = isRemoteConnected
          ? remoteCensoRecords.map((r) => (r['datosDinamicos'] as Map?) ?? r).toList()
          : censoRecordsBox.values.cast<CensoRecordModel>().map((r) => r.datosDinamicos).toList();

      final Map<String, String> linkedEscolaridad = {};
      for (final recordData in allCensoRecords) {
        final familiares = (recordData is Map ? recordData['familiares'] : null) as List? ?? [];
        for (final m in familiares) {
          if (m is Map) {
            final String? hId = m['habitanteId']?.toString();
            final String? ced = m['cedula']?.toString();
            final String edu = m['escolaridad']?.toString() ?? '';
            if (edu.isNotEmpty) {
              if (hId != null && hId.isNotEmpty) linkedEscolaridad[hId] = edu;
              if (ced != null && ced.isNotEmpty) linkedEscolaridad[ced] = edu;
            }
          }
        }
      }

      for (final h in allHabitants) {
        final id = h['id'].toString();
        final cedula = h['cedula'].toString();
        countedHabitanteIds.add(id);

        final nombres = h['nombres'] as String? ?? '';
        final genero = h['genero'] as String? ?? '';
        if (isFemale(nombres, genero)) {
          femaleCount++;
        } else {
          maleCount++;
        }

        final ayuda = h['ayudaRecibida'] as String? ?? '';
        if (ayuda.isNotEmpty) {
          assignedAyudasCount += ayuda.split(',').where((s) => s.trim().isNotEmpty).length;
        }

        final DateTime? birthDate = h['fechaNacimiento'] as DateTime?;
        if (birthDate != null) {
          processAge(_calculateAge(birthDate));
        }

        final bool tieneDiscapacidad = h['tieneDiscapacidad'] == true;
        if (tieneDiscapacidad) {
          final desc = (h['detallesDiscapacidad'] as String? ?? '').toLowerCase();
          if (desc.contains('motor') || desc.contains('físic') || desc.contains('fisic')) {
            volMotora++;
          } else if (desc.contains('visual') || desc.contains('cieg') || desc.contains('vista')) {
            volVisual++;
          } else if (desc.contains('audit') || desc.contains('sord')) {
            volAuditiva++;
          } else if (desc.contains('intel') || desc.contains('ment') || desc.contains('cognit')) {
            volIntelectual++;
          } else {
            volMotora++;
          }
        } else {
          volNinguna++;
        }

        final edu = h['escolaridad']?.toString() ?? linkedEscolaridad[id] ?? linkedEscolaridad[cedula] ?? '';
        if (edu.isNotEmpty) {
          final matchedKey = eduCounts.keys.firstWhere(
            (k) => edu.toLowerCase().contains(k.toLowerCase()),
            orElse: () => 'Otro',
          );
          eduCounts[matchedKey] = eduCounts[matchedKey]! + 1;
        }
      }

      // Procesar datos adicionales de censos
      for (final recordData in allCensoRecords) {
        final familiares = (recordData is Map ? recordData['familiares'] : null) as List? ?? [];
        for (final m in familiares) {
          if (m is Map) {
            final String? habitanteId = m['habitanteId']?.toString();
            final isLinked = habitanteId != null && habitanteId.isNotEmpty;
            final alreadyCounted = isLinked && countedHabitanteIds.contains(habitanteId);

            final name = m['jefeFamilia']?.toString() ?? m['nombres']?.toString() ?? '';
            final edu = m['escolaridad']?.toString() ?? '';

            if (name.isNotEmpty && !alreadyCounted) {
              if (isFemale(name)) {
                femaleCount++;
              } else {
                maleCount++;
              }
            }

            final ageStr = m['edad']?.toString() ?? '';
            if (ageStr.isNotEmpty) {
              final age = int.tryParse(ageStr);
              if (age != null) processAge(age);
            }

            if (edu.isNotEmpty && !alreadyCounted) {
              final matchedKey = eduCounts.keys.firstWhere(
                (k) => edu.toLowerCase().contains(k.toLowerCase()),
                orElse: () => 'Otro',
              );
              eduCounts[matchedKey] = eduCounts[matchedKey]! + 1;
            }

            if (!alreadyCounted) {
              final discList = m['salud_discapacidad'];
              if (discList != null) {
                final str = discList.toString().toLowerCase();
                if (str.contains('ninguna') || str.isEmpty) {
                  volNinguna++;
                } else {
                  if (str.contains('motor')) volMotora++;
                  if (str.contains('visual')) volVisual++;
                  if (str.contains('audit')) volAuditiva++;
                  if (str.contains('intel')) volIntelectual++;
                }
              } else {
                volNinguna++;
              }
          }
        }
      }

      final double totalGender = (femaleCount + maleCount).toDouble();
      final fPct = totalGender > 0 ? (femaleCount / totalGender) * 100 : 0.0;
      final mPct = totalGender > 0 ? (maleCount / totalGender) * 100 : 0.0;

      final double totalAge = (children + youth + adults + seniors).toDouble();
      final double cPct = totalAge > 0 ? (children / totalAge) * 100 : 0.0;
      final double yPct = totalAge > 0 ? (youth / totalAge) * 100 : 0.0;
      final double aPct = totalAge > 0 ? (adults / totalAge) * 100 : 0.0;
      final double sPct = totalAge > 0 ? (seniors / totalAge) * 100 : 0.0;

      final double totalEdu = eduCounts.values.fold(0, (sum, val) => sum + val).toDouble();
      final double totalVol = (volNinguna + volMotora + volVisual + volAuditiva + volIntelectual).toDouble();
      final double vulnPct = totalVol > 0 ? ((volMotora + volVisual + volAuditiva + volIntelectual) / totalVol) * 100 : 0.0;

      setState(() {
        _totalInhabitants = total;
        _vulnerabilityRate = double.parse(vulnPct.toStringAsFixed(1));
        _totalCensos = totalCensosCount;
        _totalAyudas = assignedAyudasCount;
        _femalePercentage = double.parse(fPct.toStringAsFixed(1));
        _malePercentage = double.parse(mPct.toStringAsFixed(1));

        _ageDistribution = [
          _DemographicItem('Niños (0-14)', double.parse(cPct.toStringAsFixed(1)), const Color(0xFF4A90E2), Icons.child_care),
          _DemographicItem('Jóvenes (15-29)', double.parse(yPct.toStringAsFixed(1)), const Color(0xFF50E3C2), Icons.directions_run),
          _DemographicItem('Adultos (30-59)', double.parse(aPct.toStringAsFixed(1)), const Color(0xFFF5A623), Icons.person),
          _DemographicItem('Adultos Mayores (60+)', double.parse(sPct.toStringAsFixed(1)), const Color(0xFFD0021B), Icons.elderly),
        ];

        _educationLevels = eduCounts.entries.map((e) {
          final pct = totalEdu > 0 ? (e.value / totalEdu) * 100 : 0.0;
          IconData icon;
          Color color;
          switch (e.key) {
            case 'Analfabeta':
              icon = Icons.block;
              color = Colors.red.shade400;
              break;
            case 'Primaria':
              icon = Icons.menu_book;
              color = Colors.blue.shade400;
              break;
            case 'Secundaria':
              icon = Icons.school;
              color = Colors.indigo.shade400;
              break;
            case 'Técnica':
              icon = Icons.handyman;
              color = Colors.teal;
              break;
            case 'Universitaria':
              icon = Icons.account_balance;
              color = Colors.purple;
              break;
            default:
              icon = Icons.workspace_premium;
              color = Colors.pinkAccent;
          }
          return _DemographicItem(e.key, double.parse(pct.toStringAsFixed(1)), color, icon);
        }).toList();

        _vulnerabilityData = [
          _DonutSlice('Ninguna', totalVol > 0 ? double.parse(((volNinguna / totalVol) * 100).toStringAsFixed(1)) : 0.0, Colors.grey.shade400),
          _DonutSlice('Motora', totalVol > 0 ? double.parse(((volMotora / totalVol) * 100).toStringAsFixed(1)) : 0.0, const Color(0xFF416FDF)),
          _DonutSlice('Visual', totalVol > 0 ? double.parse(((volVisual / totalVol) * 100).toStringAsFixed(1)) : 0.0, Colors.teal),
          _DonutSlice('Auditiva', totalVol > 0 ? double.parse(((volAuditiva / totalVol) * 100).toStringAsFixed(1)) : 0.0, Colors.orange),
          _DonutSlice('Intelectual', totalVol > 0 ? double.parse(((volIntelectual / totalVol) * 100).toStringAsFixed(1)) : 0.0, Colors.purple),
        ];

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error agregando estadísticas reales: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openChat() {
    setState(() {
      _isChatOpen = true;
      if (_chatMessages.isEmpty) {
        _chatMessages.add(_ChatMessage(
          text: '¡Hola! Soy el Asistente de IA para estadísticas de Comuniapp. ¿En qué puedo ayudarte hoy?',
          isSystem: true,
        ));
      }
    });
  }

  void _handleUserQuery(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _chatMessages.add(_ChatMessage(text: query, isSystem: false));
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final lower = query.toLowerCase();
      String response = 'Consulta no reconocida. Puedes consultar sobre el total de habitantes, edades, escolaridad o vulnerabilidad.';
      
      if (lower.contains('total') || lower.contains('habitante') || lower.contains('poblacion')) {
        response = 'En la base de datos de la comunidad hay registrados $_totalInhabitants habitantes. Distribución por género: $_femalePercentage% femenino y $_malePercentage% masculino.';
      } else if (lower.contains('edad') || lower.contains('joven') || lower.contains('niño') || lower.contains('anciano') || lower.contains('mayor')) {
        final ageStr = _ageDistribution.map((e) => '${e.label}: ${e.percentage}%').join(', ');
        response = 'Distribución por edades calculada desde el sistema: $ageStr.';
      } else if (lower.contains('educa') || lower.contains('escolar') || lower.contains('estudio') || lower.contains('universi') || lower.contains('secunda')) {
        final eduStr = _educationLevels.map((e) => '${e.label}: ${e.percentage}%').join(', ');
        response = 'Nivel de escolaridad registrado en la comunidad: $eduStr.';
      } else if (lower.contains('vulnera') || lower.contains('discapa') || lower.contains('salud') || lower.contains('enfermedad')) {
        final vulnStr = _vulnerabilityData.map((e) => '${e.label}: ${e.value.toStringAsFixed(1)}%').join(', ');
        response = 'La tasa global de vulnerabilidad por condición o discapacidad es del $_vulnerabilityRate%. Desglose: $vulnStr.';
      }
      
      setState(() {
        _chatMessages.add(_ChatMessage(text: response, isSystem: true));
      });
    });
  }

  Widget _buildChatbotOverlay(ThemeData theme) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isChatOpen) ...[
            Container(
              width: isMobile ? size.width - 40 : 360,
              height: 450,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.yellowAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Asistente de IA Comuniapp',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'En línea',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => setState(() => _isChatOpen = false),
                        ),
                      ],
                    ),
                  ),
                  
                  // Chat Messages List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        return Align(
                          alignment: msg.isSystem ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: msg.isSystem ? Colors.grey.shade100 : const Color(0xFF2575FC),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: msg.isSystem ? Radius.zero : const Radius.circular(16),
                                bottomRight: msg.isSystem ? const Radius.circular(16) : Radius.zero,
                              ),
                              border: msg.isSystem ? Border.all(color: Colors.black.withOpacity(0.04)) : null,
                            ),
                            constraints: BoxConstraints(maxWidth: (isMobile ? size.width - 40 : 360) * 0.75),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.isSystem ? Colors.black87 : Colors.white,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Quick Replies list
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      children: [
                        _quickReplyChip('Habitantes Totales', '¿Total de habitantes?'),
                        _quickReplyChip('Rango de Edad', '¿Distribución por edades?'),
                        _quickReplyChip('Nivel de Estudio', '¿Condición de educación?'),
                        _quickReplyChip('Vulnerabilidades', '¿Tasa de vulnerabilidad?'),
                      ],
                    ),
                  ),

                  // Input Box
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatInputController,
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu consulta...',
                              hintStyle: TextStyle(color: Colors.black38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onSubmitted: (val) {
                              _handleUserQuery(val);
                              _chatInputController.clear();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF2575FC)),
                          onPressed: () {
                            _handleUserQuery(_chatInputController.text);
                            _chatInputController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Floating Action Button
          GestureDetector(
            onTap: () {
              if (_isChatOpen) {
                setState(() => _isChatOpen = false);
              } else {
                _openChat();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2575FC).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isChatOpen ? Icons.close : Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickReplyChip(String label, String query) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: Colors.blue.shade50,
        side: BorderSide(color: Colors.blue.shade100),
        label: Text(label, style: const TextStyle(color: Color(0xFF2575FC), fontSize: 11, fontWeight: FontWeight.bold)),
        padding: EdgeInsets.zero,
        onPressed: () => _handleUserQuery(query),
      ),
    );
  }

  static const bool _showAiFeatures = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return MultiBlocListener(
      listeners: [
        BlocListener<CensosBloc, CensosState>(
          listener: (context, state) {
            if (state is CensoOperationSuccess || state is CensosLoaded) {
              _loadAndAggregateData();
            }
          },
        ),
        BlocListener<HabitantsBloc, HabitantsState>(
          listener: (context, state) {
            if (state is HabitantsLoaded) {
              _loadAndAggregateData();
            }
          },
        ),
      ],
      child: CustomScaffold(
        drawer: SideMenu(scaffoldKey: scaffoldKey),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Stack(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──────────────────────────────────────────────────
                          _buildHeader(theme),
                          const SizedBox(height: 24),

                          // ── KPI Cards Grid ──────────────────────────────────────────
                          _buildKpiGrid(isWide),
                          const SizedBox(height: 24),

                          // ── Demographics & Gender Row ────────────────────────────────
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 1, child: _buildAgeDistributionCard(theme)),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 1, child: _buildGenderCard(theme)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildAgeDistributionCard(theme),
                                    const SizedBox(height: 20),
                                    _buildGenderCard(theme),
                                  ],
                                ),
                          const SizedBox(height: 24),

                          // ── Education & Vulnerability Row ────────────────────────────
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 1, child: _buildEducationCard(theme)),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 1, child: _buildVulnerabilityCard(theme)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildEducationCard(theme),
                                    const SizedBox(height: 20),
                                    _buildVulnerabilityCard(theme),
                                  ],
                                ),
                          const SizedBox(height: 24),

                          // ── AI Insights Premium Card (Oculto por defecto) ───────────
                          if (_showAiFeatures) ...[
                            _buildAiInsightsCard(theme),
                            const SizedBox(height: 80),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── AI Chatbot Floating Overlay (Oculto por defecto) ─────────────
                  if (_showAiFeatures) _buildChatbotOverlay(theme),
                ],
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de la Comunidad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Resumen demográfico, educativo y de vulnerabilidades',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
        // Period Selector with custom glass design
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1D265A),
              value: _selectedPeriod,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              items: _periods
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPeriod = val);
                  _loadAndAggregateData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── KPI Grid ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(bool isWide) {
    final cards = [
      _KpiData('Habitantes Registrados', '$_totalInhabitants', 'Total', Icons.people_alt, const Color(0xFF4A90E2), true),
      _KpiData('Tasa de Vulnerabilidad', '$_vulnerabilityRate%', 'Calculado', Icons.health_and_safety, Colors.teal, true),
      _KpiData('Censos Finalizados', '$_totalCensos', 'Completo', Icons.assignment_turned_in, Colors.orange, true),
      _KpiData('Ayudas Entregadas', '$_totalAyudas', 'Entregado', Icons.volunteer_activism, Colors.purple, false),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((kpi) {
            return SizedBox(
              width: itemWidth,
              child: _buildKpiCard(kpi),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData kpi) {
    final contrastColor = kpi.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kpi.color, // Solid background color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kpi.color.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: contrastColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(kpi.icon, color: contrastColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: contrastColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    kpi.change,
                    style: TextStyle(
                      color: contrastColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: contrastColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.label,
              style: TextStyle(
                fontSize: 13,
                color: contrastColor.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Insights Premium Box ────────────────────────────────────────────────

  Widget _buildAiInsightsCard(ThemeData theme) {
    final youthPctStr = _ageDistribution.length > 1 ? '${_ageDistribution[1].percentage}%' : '0%';
    final seniorPctStr = _ageDistribution.length > 3 ? '${_ageDistribution[3].percentage}%' : '0%';
    final secEduStr = _educationLevels.firstWhere(
      (e) => e.label == 'Secundaria',
      orElse: () => const _DemographicItem('Secundaria', 0, Colors.black, Icons.school),
    ).percentage;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A11CB),
            Color(0xFF2575FC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              Icons.psychology,
              size: 150,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.yellowAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Insights de IA (En Tiempo Real)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Diagnóstico Socio-Demográfico de la Comunidad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Basado en la consolidación real de censos y habitantes registrados ($_totalInhabitants registrados en total):',
                  style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildInsightBullet(
                  Icons.explore,
                  'Distribución de Fuerza Laboral:',
                  'El $youthPctStr de la población registrada está en el rango de jóvenes (15-29 años). El sistema recomienda orientar proyectos a la capacitación activa.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _buildInsightBullet(
                  Icons.favorite,
                  'Atenciones Sanitarias Prioritarias:',
                  'Con un $seniorPctStr de adultos mayores y una tasa de vulnerabilidad del $_vulnerabilityRate%, se aconseja estructurar visitas asistenciales focalizadas.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _buildInsightBullet(
                  Icons.trending_up,
                  'Estrategia de Educación Productiva:',
                  'La educación secundaria alcanza un $secEduStr% de la muestra escolarizada en la comunidad, lo que permite proyectar cursos de especialización técnica.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBullet(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xEEFFFFFF),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Age Distribution Card ─────────────────────────────────────────────────

  Widget _buildAgeDistributionCard(ThemeData theme) {
    return _ChartCard(
      title: 'Distribución de Edades',
      subtitle: 'Rango generacional de los habitantes',
      icon: Icons.pie_chart,
      child: Column(
        children: _ageDistribution.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${item.percentage}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: item.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.percentage / 100,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Gender Distribution Card ───────────────────────────────────────────────

  Widget _buildGenderCard(ThemeData theme) {
    return _ChartCard(
      title: 'Distribución por Género',
      subtitle: 'Balance poblacional masculino y femenino',
      icon: Icons.person_search,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radial Gauge representing Gender
          SizedBox(
            height: 180,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  showLabels: false,
                  showTicks: false,
                  startAngle: 270,
                  endAngle: 270,
                  radiusFactor: 0.85,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.18,
                    color: Color(0xFF4A90E2), // Male primary
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: _femalePercentage,
                      width: 0.18,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: const Color(0xFFF5A623), // Female primary
                    )
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.1,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$_totalInhabitants',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGenderLegend(
                'Femenino',
                '$_femalePercentage%',
                const Color(0xFFF5A623),
                Icons.female,
              ),
              _buildGenderLegend(
                'Masculino',
                '$_malePercentage%',
                const Color(0xFF4A90E2),
                Icons.male,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderLegend(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // ── Educational Level Card ─────────────────────────────────────────────────

  Widget _buildEducationCard(ThemeData theme) {
    return _ChartCard(
      title: 'Nivel Educativo',
      subtitle: 'Grado máximo alcanzado en la comunidad',
      icon: Icons.menu_book,
      child: Column(
        children: _educationLevels.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 14, color: item.color),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${item.percentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.percentage / 100,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Vulnerability Card ─────────────────────────────────────────────────────

  Widget _buildVulnerabilityCard(ThemeData theme) {
    return _ChartCard(
      title: 'Vulnerabilidad por Discapacidad',
      subtitle: 'Distribución según condición física o intelectual',
      icon: Icons.accessible,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: _DonutChartWidget(
              slices: _vulnerabilityData,
              vulnerabilityRate: _vulnerabilityRate,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _vulnerabilityData.map((s) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${s.label} (${s.value}%)',
                    style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Shared Card Wrapper ────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Donut Chart Custom Painter ─────────────────────────────────────────────

class _DonutChartWidget extends StatelessWidget {
  final List<_DonutSlice> slices;
  final double vulnerabilityRate;
  const _DonutChartWidget({
    required this.slices,
    required this.vulnerabilityRate,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(slices: slices),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${vulnerabilityRate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Vulnerables',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.32;

    double startAngle = -math.pi / 2;
    const gapAngle = 0.02;

    for (final slice in slices) {
      final sweepAngle = (slice.value / 100) * 2 * math.pi - gapAngle;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Helper Models ──────────────────────────────────────────────────────────

class _DemographicItem {
  final String label;
  final double percentage;
  final Color color;
  final IconData icon;
  const _DemographicItem(this.label, this.percentage, this.color, this.icon);
}

class _DonutSlice {
  final String label;
  final double value;
  final Color color;
  const _DonutSlice(this.label, this.value, this.color);
}

class _KpiData {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final bool isPositive;
  const _KpiData(this.label, this.value, this.change, this.icon, this.color, this.isPositive);
}

class _ChatMessage {
  final String text;
  final bool isSystem;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isSystem}) : timestamp = DateTime.now();
}

