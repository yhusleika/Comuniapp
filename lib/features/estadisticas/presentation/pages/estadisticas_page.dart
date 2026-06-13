import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  String _selectedPeriod = 'Este Mes';
  final List<String> _periods = ['Esta Semana', 'Este Mes', 'Este Año'];

  bool _isChatOpen = false;
  final List<_ChatMessage> _chatMessages = [];
  final _chatInputController = TextEditingController();

  // ── Mock data for the Premium Dashboard ────────────────────────────────────
  
  // Total Inhabitants: 1,248
  final int _totalInhabitants = 1248;
  
  // Age distribution: Children (15%), Youth (40%), Adults (30%), Seniors (15%)
  final List<_DemographicItem> _ageDistribution = [
    _DemographicItem('Niños (0-14)', 15, const Color(0xFF4A90E2), Icons.child_care),
    _DemographicItem('Jóvenes (15-29)', 40, const Color(0xFF50E3C2), Icons.directions_run),
    _DemographicItem('Adultos (30-59)', 30, const Color(0xFFF5A623), Icons.person),
    _DemographicItem('Adultos Mayores (60+)', 15, const Color(0xFFD0021B), Icons.elderly),
  ];

  // Gender distribution: Female (52%), Male (48%)
  final double _femalePercentage = 52.0;
  final double _malePercentage = 48.0;

  // Educational level distribution
  final List<_DemographicItem> _educationLevels = [
    _DemographicItem('Primaria', 25, Colors.blue.shade400, Icons.menu_book),
    _DemographicItem('Secundaria', 45, Colors.indigo.shade400, Icons.school),
    _DemographicItem('Técnico Aspirante', 15, Colors.teal, Icons.handyman),
    _DemographicItem('Universitario', 12, Colors.purple, Icons.account_balance),
    _DemographicItem('Postgrado', 3, Colors.pinkAccent, Icons.workspace_premium),
  ];

  // Vulnerability/Disability distribution
  final List<_DonutSlice> _vulnerabilityData = [
    _DonutSlice('Ninguna', 82, Colors.grey.shade400),
    _DonutSlice('Motora', 6, const Color(0xFF416FDF)),
    _DonutSlice('Visual', 5, Colors.teal),
    _DonutSlice('Auditiva', 4, Colors.orange),
    _DonutSlice('Intelectual', 3, Colors.purple),
  ];

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
  }

  @override
  void dispose() {
    _animController.dispose();
    _chatInputController.dispose();
    super.dispose();
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

    // Simulate thinking delay
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      
      final lower = query.toLowerCase();
      String response = 'No entiendo tu consulta. Intenta preguntar sobre el total de habitantes, edad, escolaridad o vulnerabilidad.';
      
      if (lower.contains('total') || lower.contains('habitante') || lower.contains('poblacion')) {
        response = 'El total de habitantes registrados en la comunidad es de 1,248 personas. El 52% representa al género femenino y el 48% al masculino.';
      } else if (lower.contains('edad') || lower.contains('joven') || lower.contains('niño') || lower.contains('anciano') || lower.contains('mayor')) {
        response = 'Nuestra población es mayormente joven: el 40% son jóvenes (15-29 años), seguido por un 30% de adultos (30-59 años), y un 15% de niños y 15% de adultos mayores respectivamente.';
      } else if (lower.contains('educa') || lower.contains('escolar') || lower.contains('estudio') || lower.contains('universi') || lower.contains('secunda')) {
        response = 'La escolaridad se concentra principalmente en secundaria (45%), seguido de primaria (25%), educación técnica (15%), universitaria (12%) y postgrado (3%).';
      } else if (lower.contains('vulnera') || lower.contains('discapa') || lower.contains('salud') || lower.contains('enfermedad')) {
        response = 'La tasa general de vulnerabilidad física/intelectual es del 18.0%. Esto incluye condiciones motoras (6%), visuales (5%), auditivas (4%) e intelectuales (3%).';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: Stack(
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

                  // ── AI-Generated Insights Premium Box ───────────────────────
                  _buildAiInsightsCard(theme),
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
                ],
              ),
            ),
          ),
          _buildChatbotOverlay(theme),
        ],
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
              onChanged: (val) => setState(() => _selectedPeriod = val!),
            ),
          ),
        ),
      ],
    );
  }

  // ── KPI Grid ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(bool isWide) {
    final cards = [
      _KpiData('Habitantes Registrados', '1,248', '+12% este mes', Icons.people_alt, const Color(0xFF4A90E2), true),
      _KpiData('Tasa de Vulnerabilidad', '18.0%', '+1.2%', Icons.health_and_safety, Colors.teal, true),
      _KpiData('Censos Finalizados', '7', 'Completo', Icons.assignment_turned_in, Colors.orange, true),
      _KpiData('Ayudas Pendientes', '42', 'En cola', Icons.volunteer_activism, Colors.purple, false),
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
                            'Insights Generados por IA',
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
                const Text(
                  'Basado en la consolidación de censos locales y características registradas de los habitantes:',
                  style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildInsightBullet(
                  Icons.explore,
                  'Fuerza Laboral Joven Mandatoria:',
                  'El 40% de la población se encuentra en el rango de juventud (15-29 años). Existe una oportunidad masiva para talleres de capacitación tecnológica e inserción laboral.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _buildInsightBullet(
                  Icons.favorite,
                  'Salud Preventiva Focalizada:',
                  'Con un 15% de adultos mayores y una tasa de vulnerabilidad por discapacidad del 18.0%, se recomienda estructurar jornadas médicas a domicilio coordinando con el sector salud.',
                ),
                const Divider(color: Colors.white24, height: 24),
                _buildInsightBullet(
                  Icons.trending_up,
                  'Estrategia de Educación Productiva:',
                  'El nivel de educación secundaria alcanza el 45% mientras que el técnico/universitario es del 27%. Alianzas con institutos técnicos impulsarán el desarrollo económico regional.',
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
            child: _DonutChartWidget(slices: _vulnerabilityData),
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
  const _DonutChartWidget({required this.slices});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(slices: slices),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '18%',
              style: TextStyle(
                fontSize: 24,
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

