import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/dashboard_stats.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(const LoadDashboard()),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateToModule(String module) {
    switch (module) {
      case 'Ayudas':
        context.push('/ayudas');
        break;
      case 'Censos':
        context.push('/censos');
        break;
      case 'Habitantes':
        context.push('/habitants');
        break;
      case 'Eventos':
        context.push('/eventos');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount =
        screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;
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
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is! DashboardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = state.stats;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inicio',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildIndicatorGrid(
                    stats, crossAxisCount, childAspectRatio),
                const SizedBox(height: 30),
                _buildTimeline(stats),
                const SizedBox(height: 30),
                _buildProjectTable(theme, stats),
                const SizedBox(height: 30),
                _buildRecentActivity(theme, stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndicatorGrid(
      DashboardStats stats, int crossAxisCount, double childAspectRatio) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: [
        _IndicatorCard(
          title: 'Ayudas',
          value: '${stats.counts['Ayudas'] ?? 0}',
          icon: Icons.volunteer_activism_outlined,
          color: Colors.blue,
          onTap: () => _navigateToModule('Ayudas'),
        ),
        _IndicatorCard(
          title: 'Censos',
          value: '${stats.counts['Censos'] ?? 0}',
          icon: Icons.analytics_outlined,
          color: Colors.green,
          onTap: () => _navigateToModule('Censos'),
        ),
        _IndicatorCard(
          title: 'Habitantes',
          value: '${stats.counts['Habitantes'] ?? 0}',
          icon: Icons.people_outline,
          color: Colors.orange,
          onTap: () => _navigateToModule('Habitantes'),
        ),
        _IndicatorCard(
          title: 'Eventos',
          value: '${stats.counts['Eventos'] ?? 0}',
          icon: Icons.assignment_outlined,
          color: Colors.purple,
          onTap: () => _navigateToModule('Eventos'),
        ),
      ],
    );
  }

  Widget _buildTimeline(DashboardStats stats) {
    return _SectionContainer(
      title: 'Actividades del Mes',
      child: stats.eventos.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay actividades registradas para este mes.'),
            )
          : Column(
              children: List.generate(
                  stats.eventos.take(5).length, (index) {
                final item = stats.eventos[index];
                final dateStr = DateFormat('dd MMM')
                    .format(item.createdAt.toLocal());
                return _TimelineItem(
                  title: item.name,
                  date: dateStr,
                  isFirst: index == 0,
                  isLast: index == stats.eventos.take(5).length - 1,
                  status: item.status,
                );
              }),
            ),
    );
  }

  Widget _buildProjectTable(ThemeData theme, DashboardStats stats) {
    final isDark = theme.brightness == Brightness.dark;
    final proyectos = stats.proyectos;

    return _SectionContainer(
      title: 'Seguimiento de Proyectos',
      child: SizedBox(
        height: 300,
        child: proyectos.isEmpty
            ? const Center(child: Text('No hay proyectos activos registrados.'))
            : DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                columns: [
                  DataColumn2(
                      label: Text('Proyecto',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87)),
                      size: ColumnSize.L),
                  DataColumn2(
                      label: Text('Encargado',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87)),
                      size: ColumnSize.M),
                  DataColumn2(
                      label: Text('Progreso',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87)),
                      size: ColumnSize.M),
                  DataColumn2(
                      label: Text('Estatus',
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87)),
                      size: ColumnSize.S),
                ],
                rows: proyectos.map((proj) {
                  final status = proj.status;
                  final double progress = status == 'Culminado' ||
                          status == 'Completado'
                      ? 1.0
                      : 0.5;
                  final Color color = status == 'Culminado' ||
                          status == 'Completado'
                      ? Colors.green
                      : Colors.blue;
                  return DataRow(
                    onSelectChanged: (_) => context.push('/eventos'),
                    cells: [
                      DataCell(Text(proj.name,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold))),
                      DataCell(Text(proj.responsible ?? 'No asignado',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white70 : Colors.black87))),
                      DataCell(LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          color: color)),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme, DashboardStats stats) {
    final isDark = theme.brightness == Brightness.dark;

    return _SectionContainer(
      title: 'Actividad Reciente (Últimas 10)',
      child: stats.recentActivity.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No hay actividad reciente')),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.recentActivity.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final act = stats.recentActivity[index];
                IconData icon;
                Color color;
                switch (act.type) {
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

                final dateStr = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(act.date.toLocal());

                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icon, color: color)),
                  title: Text(act.title,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      act.subtitle != null
                          ? '${act.subtitle} • $dateStr'
                          : dateStr,
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54)),
                );
              },
            ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IndicatorCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  Color _getContrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final contrastColor = _getContrastColor(color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color,
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
        ),
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
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
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
        beforeLineStyle:
            LineStyle(color: isDark ? Colors.white24 : Colors.black12),
        indicatorStyle: IndicatorStyle(
          width: 30,
          color: status == 'Culminado' || status == 'Completado'
              ? Colors.green
              : Colors.blue,
          iconStyle: status == 'Culminado' || status == 'Completado'
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
