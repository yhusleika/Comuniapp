import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import 'dart:io';
import '../bloc/reports_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportsBloc>()..add(LoadReports()),
      child: const ReportsView(),
    );
  }
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Reportes Comunitarios',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: BlocBuilder<ReportsBloc, ReportsState>(
                    builder: (context, state) {
                      if (state is ReportsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ReportsLoaded) {
                        if (state.reports.isEmpty) {
                          return const Center(child: Text('No hay reportes.'));
                        }
                        return ListView.builder(
                          itemCount: state.reports.length,
                          itemBuilder: (context, index) {
                            final reporte = state.reports[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 2,
                              child: ListTile(
                                leading: _buildLeadingImage(reporte.fotosPaths),
                                title: Text(reporte.titulo),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(reporte.tipo),
                                    Text('Prioridad: ${reporte.prioridad}',
                                        style: TextStyle(
                                            color: _getPriorityColor(
                                                reporte.prioridad))),
                                  ],
                                ),
                                trailing: Text(reporte.estatus),
                              ),
                            );
                          },
                        );
                      } else if (state is ReportsError) {
                        return Center(child: Text(state.message));
                      }
                      return Container();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingImage(List<String> paths) {
    if (paths.isEmpty) return const Icon(Icons.image_not_supported);
    final path = paths.first;
    return kIsWeb
        ? Image.network(path,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image))
        : (path.startsWith('http') || path.startsWith('assets/'))
            ? Image.network(path,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image))
            : Image.file(File(path),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image));
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critica':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'media':
        return Colors.yellow[800]!;
      default:
        return Colors.green;
    }
  }
}
