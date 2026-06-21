import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/mongodb_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // State for the interactive radial gauge
  String _selectedCategory = 'Global';
  double _selectedValue = 70; // Default average or global value

  Map<String, Map<String, dynamic>> _categories = {
    'Ayudas': {'value': 0.0, 'color': Colors.blue},
    'Censos': {'value': 0.0, 'color': Colors.green},
    'Habitantes': {'value': 0.0, 'color': Colors.orange},
    'Eventos': {'value': 0.0, 'color': Colors.purple},
  };

  Map<String, int> _counts = {
    'Habitantes': 0,
    'Ayudas': 0,
    'Censos': 0,
    'Eventos': 0,
  };

  List<dynamic> _recentActivity = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final service = sl<MongoDBService>();
      final data = await service.getStats();
      
      if (data.isNotEmpty && data['counts'] != null) {
        final counts = data['counts'];
        setState(() {
          _counts = {
            'Habitantes': counts['habitants'] ?? 0,
            'Ayudas': counts['ayudas'] ?? 0,
            'Censos': counts['censos'] ?? 0,
            'Eventos': counts['eventos'] ?? 0,
          };
          
          // Calcular valores de sincronización estipulados vs totales (demo realística)
          _categories['Habitantes']!['value'] = _counts['Habitantes']! > 0 ? 100.0 : 0.0;
          _categories['Ayudas']!['value'] = _counts['Ayudas']! > 0 ? 100.0 : 0.0;
          _categories['Censos']!['value'] = _counts['Censos']! > 0 ? 100.0 : 0.0;
          _categories['Eventos']!['value'] = _counts['Eventos']! > 0 ? 100.0 : 0.0;
          
          _recentActivity = data['recentActivity'] ?? [];
          
          // Re-set global average
          _selectedValue = (_categories.values.map((e) => e['value'] as double).reduce((a, b) => a + b)) / 4;
          if (_selectedCategory != 'Global') {
            _selectedValue = _categories[_selectedCategory]!['value'];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = 'Global';
        _selectedValue = 70; // Average
      } else {
        _selectedCategory = category;
        _selectedValue = _categories[category]!['value'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 2;
    final double childAspectRatio = screenWidth > 1200
        ? 2.5
        : screenWidth > 600
            ? 2.2
            : screenWidth > 380
                ? 1.9
                : 1.5;

    return CustomScaffold(
      scaffoldKey: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Control',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 1. Grid de Indicadores (Cards)
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: _categories.entries.map((e) {
                return _IndicatorCard(
                  title: e.key,
                  value: '${_counts[e.key] ?? 0}',
                  icon: e.key == 'Ayudas'
                      ? Icons.volunteer_activism_outlined
                      : e.key == 'Censos'
                          ? Icons.analytics_outlined
                          : e.key == 'Habitantes'
                              ? Icons.people_outline
                              : Icons.assignment_outlined,
                  color: e.value['color'],
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // 2. Gráfico de Progreso Radial
            _SectionContainer(
              title: 'Sincronización con la Nube',
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        _buildRadialAxis(1.0, _categories['Ayudas']!['value'],
                            _categories['Ayudas']!['color']),
                        _buildRadialAxis(0.85, _categories['Censos']!['value'],
                            _categories['Censos']!['color']),
                        _buildRadialAxis(
                            0.70,
                            _categories['Habitantes']!['value'],
                            _categories['Habitantes']!['color']),
                        _buildRadialAxis(
                          0.55,
                          _categories['Eventos']!['value'],
                          _categories['Eventos']!['color'],
                          annotation: GaugeAnnotation(
                            widget: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_selectedValue.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  _selectedCategory,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            angle: 90,
                            positionFactor: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _categories.entries.map((e) {
                      final isSelected = _selectedCategory == e.key;
                      return GestureDetector(
                        onTap: () => _selectCategory(e.key),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: (_selectedCategory == 'Global' || isSelected)
                              ? 1.0
                              : 0.4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: e.value['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. Línea de Tiempo (Timeline)
            _SectionContainer(
              title: 'Actividades del Mes',
              child: Column(
                children: [
                  _TimelineItem(
                    title: 'Jornada de Vacunación',
                    date: '15 Feb',
                    isFirst: true,
                    status: 'Culminado',
                  ),
                  _TimelineItem(
                    title: 'Censo Sector A',
                    date: '18 Feb',
                    status: 'En Progreso',
                  ),
                  _TimelineItem(
                    title: 'Entrega de Ayudas',
                    date: '22 Feb',
                    isLast: true,
                    status: 'Pendiente',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. Tabla de Seguimiento de Proyectos
            _SectionContainer(
              title: 'Seguimiento de Proyectos',
              child: SizedBox(
                height: 300,
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 600,
                  columns: [
                    DataColumn2(label: Text('Encargado', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)), size: ColumnSize.L),
                    DataColumn2(label: Text('Fechas', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)), size: ColumnSize.M),
                    DataColumn2(label: Text('Progreso', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)), size: ColumnSize.M),
                    DataColumn2(label: Text('Estatus', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)), size: ColumnSize.S),
                  ],
                  rows: [
                    _projectRow('Juan Pérez', '01/02 - 28/02', 0.8, 'Terminado',
                        Colors.green),
                    _projectRow('María García', '10/02 - 15/03', 0.4,
                        'En Progreso', Colors.blue),
                    _projectRow('Carlos Ruiz', '01/03 - 30/03', 0.0,
                        'Por Iniciar', Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 5. Tabla de Actividad Reciente
            _SectionContainer(
              title: 'Actividad Reciente',
              child: _recentActivity.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No hay actividad reciente')),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivity.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final act = _recentActivity[index];
                        IconData icon;
                        Color color;
                        switch (act['type']) {
                          case 'habitante':
                            icon = Icons.person;
                            color = Colors.orange;
                            break;
                          case 'reporte':
                            icon = Icons.warning;
                            color = Colors.red;
                            break;
                          case 'evento':
                            icon = Icons.event;
                            color = Colors.purple;
                            break;
                          default:
                            icon = Icons.info;
                            color = Colors.blue;
                        }
                        
                        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(act['date']).toLocal());
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(icon, color: color)
                          ),
                          title: Text(act['title'], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          subtitle: Text(act['subtitle'] != null ? '${act['subtitle']} • $dateStr' : dateStr, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  RadialAxis _buildRadialAxis(double radius, double value, Color color,
      {GaugeAnnotation? annotation}) {
    return RadialAxis(
      showLabels: false,
      showTicks: false,
      startAngle: 270,
      endAngle: 270,
      radiusFactor: radius,
      axisLineStyle: const AxisLineStyle(
        thickness: 0.1,
        color: Colors.black12,
        thicknessUnit: GaugeSizeUnit.factor,
      ),
      pointers: <GaugePointer>[
        RangePointer(
          value: value,
          width: 0.1,
          sizeUnit: GaugeSizeUnit.factor,
          color: color,
          cornerStyle: CornerStyle.bothCurve,
        ),
      ],
      annotations: annotation != null ? [annotation] : null,
    );
  }

  DataRow _projectRow(
      String name, String date, double progress, String status, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87);
    return DataRow(cells: [
      DataCell(Text(name, style: textStyle)),
      DataCell(Text(date, style: textStyle)),
      DataCell(LinearProgressIndicator(
          value: progress, backgroundColor: isDark ? Colors.white12 : Colors.black12, color: color)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(status,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      )),
    ]);
  }
}

class _IndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _IndicatorCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  Color _getContrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final contrastColor = _getContrastColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color, // Solid color background block
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: contrastColor.withOpacity(0.2),
            child: Icon(icon, color: contrastColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: contrastColor.withOpacity(0.85),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: contrastColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.date,
    required this.status,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 80,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        beforeLineStyle: LineStyle(color: isDark ? Colors.white24 : Colors.black12),
        indicatorStyle: IndicatorStyle(
          width: 30,
          color: status == 'Culminado' ? Colors.green : Colors.blue,
          iconStyle: status == 'Culminado'
              ? IconStyle(iconData: Icons.check, color: Colors.white)
              : null,
        ),
        endChild: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '$date • $status',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
