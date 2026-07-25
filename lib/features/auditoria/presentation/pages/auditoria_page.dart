import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../core/services/document_export_service.dart';

import '../../domain/entities/audit_log.dart';
import '../bloc/auditoria_bloc.dart';
import '../bloc/auditoria_event.dart';
import '../bloc/auditoria_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audit_logger_service.dart';

class AuditoriaPage extends StatelessWidget {
  const AuditoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuditoriaBloc>()..add(const LoadAuditLogs()),
      child: const AuditoriaView(),
    );
  }
}

class AuditoriaView extends StatefulWidget {
  const AuditoriaView({super.key});

  @override
  State<AuditoriaView> createState() => _AuditoriaViewState();
}

class _AuditoriaViewState extends State<AuditoriaView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<AuditLog> _logs = [];

  // Estados de filtros
  DateTimeRange? _selectedDateRange;
  String _selectedUserFilter = 'Todos';
  String _selectedRoleFilter = 'Todos';

  List<String> get _availableUsers {
    final List<String> users = _logs.map((log) => log.user).toSet().toList();
    users.sort();
    return ['Todos', ...users];
  }

  List<String> get _availableRoles {
    final List<String> roles = _logs.map((log) => log.role).toSet().toList();
    roles.sort();
    return ['Todos', ...roles];
  }

  List<AuditLog> get _filteredLogs {
    return _logs.where((log) {
      if (_selectedDateRange != null) {
        final start = DateUtils.dateOnly(_selectedDateRange!.start);
        final end = DateUtils.dateOnly(_selectedDateRange!.end).add(const Duration(days: 1));
        if (log.dateTime.isBefore(start) || log.dateTime.isAfter(end)) {
          return false;
        }
      }
      if (_selectedUserFilter != 'Todos' && log.user != _selectedUserFilter) {
        return false;
      }
      if (_selectedRoleFilter != 'Todos' && log.role != _selectedRoleFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _exportAuditToPDF() async {
    final list = _filteredLogs;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros de auditoría para exportar')),
      );
      return;
    }

    await DocumentExportService.exportToPDF(
      moduleName: 'AUDITORÍA',
      reportSubtitle: 'Reporte Oficial de Movimientos y Seguridad',
      reportTitle: 'REPORTE FORMAL DE AUDITORÍA',
      description: 'El presente documento compila las últimas acciones críticas realizadas dentro del sistema ComuniApp, con el fin de auditar la integridad de la base de datos y la seguridad de los accesos de usuario.',
      headers: ['Usuario', 'Rol', 'Acción Realizada', 'Fecha y Hora'],
      data: list.map((log) => [
        log.user,
        log.role,
        log.action,
        DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dateTime),
      ]).toList(),
      fileName: 'reporte_auditoria_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF de auditoría descargado'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _exportAuditToExcel() async {
    final list = _filteredLogs;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros de auditoría para exportar')),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Header
    sheetObject.appendRow([
      TextCellValue('Usuario'),
      TextCellValue('Rol'),
      TextCellValue('Acción Realizada'),
      TextCellValue('Fecha y Hora')
    ]);

    // Data
    for (var log in list) {
      sheetObject.appendRow([
        TextCellValue(log.user),
        TextCellValue(log.role),
        TextCellValue(log.action),
        TextCellValue(DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dateTime))
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.save(
        'reporte_auditoria.xlsx',
        fileBytes,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: BlocConsumer<AuditoriaBloc, AuditoriaState>(
        listener: (context, state) {
          if (state is AuditoriaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AuditoriaLoading && _logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuditoriaLoaded) {
            _logs = state.logs.map((log) {
              final rawUser = log.user.trim();
              final displayUser = rawUser.isEmpty ? 'admin' : rawUser;
              final displayRole = AuditLoggerService.formatRole(log.role);
              final displayAction = AuditLoggerService.sanitizeAction(log.action);
              return AuditLog(
                id: log.id,
                user: displayUser,
                role: displayRole,
                action: displayAction,
                dateTime: log.dateTime,
              );
            }).toList();
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
              // Responsive Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auditoría y Control',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Historial de movimientos y seguridad (Lectura)',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Excel Export Button
                      Tooltip(
                        message: 'Exportar Historial a Excel',
                        child: IconButton(
                          onPressed: _exportAuditToExcel,
                          icon: const Icon(Icons.table_view, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.all(12),
                            elevation: 3,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // PDF Export Button formal
                      Tooltip(
                        message: 'Exportar Historial formal a PDF',
                        child: IconButton(
                          onPressed: _exportAuditToPDF,
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.all(12),
                            elevation: 3,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Filter Bar Premium Card
              Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.filter_alt_outlined, color: Color(0xFF416FDF)),
                              SizedBox(width: 8),
                              Text(
                                'Filtros de Búsqueda',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedDateRange != null ||
                              _selectedUserFilter != 'Todos' ||
                              _selectedRoleFilter != 'Todos')
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = null;
                                  _selectedUserFilter = 'Todos';
                                  _selectedRoleFilter = 'Todos';
                                });
                              },
                              icon: const Icon(Icons.filter_alt_off, size: 18, color: Colors.redAccent),
                              label: const Text(
                                'Limpiar Filtros',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double spacing = 16;
                          final double itemWidth = constraints.maxWidth > 720
                              ? (constraints.maxWidth - spacing * 2) / 3
                              : constraints.maxWidth;

                          final dateRangeText = _selectedDateRange == null
                              ? 'Filtrar por Fecha'
                              : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';

                          Widget datePickerButton = InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                initialDateRange: _selectedDateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF416FDF),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDateRange = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF416FDF)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      dateRangeText,
                                      style: TextStyle(
                                        color: _selectedDateRange == null ? Colors.black38 : Colors.black87,
                                        fontWeight: _selectedDateRange == null ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          Widget userDropdown = DropdownButtonFormField<String>(
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            value: _availableUsers.contains(_selectedUserFilter) ? _selectedUserFilter : 'Todos',
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Filtrar por Usuario',
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF416FDF)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _availableUsers.map((u) {
                              return DropdownMenuItem<String>(
                                value: u,
                                child: Text(u, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedUserFilter = val!;
                              });
                            },
                          );

                          Widget roleDropdown = DropdownButtonFormField<String>(
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            value: _availableRoles.contains(_selectedRoleFilter) ? _selectedRoleFilter : 'Todos',
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Filtrar por Rol',
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF416FDF)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _availableRoles.map((r) {
                              return DropdownMenuItem<String>(
                                value: r,
                                child: Text(r, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedRoleFilter = val!;
                              });
                            },
                          );

                          if (constraints.maxWidth > 720) {
                            return Row(
                              children: [
                                Expanded(child: datePickerButton),
                                SizedBox(width: spacing),
                                Expanded(child: userDropdown),
                                SizedBox(width: spacing),
                                Expanded(child: roleDropdown),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                datePickerButton,
                                SizedBox(height: spacing),
                                userDropdown,
                                SizedBox(height: spacing),
                                roleDropdown,
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Table card
              Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                           'Historial de Eventos de Seguridad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 400,
                        child: Theme(
                          data: theme.copyWith(
                            cardColor: Colors.white,
                            textTheme: theme.textTheme.apply(
                              bodyColor: Colors.black87,
                              displayColor: Colors.black87,
                            ),
                          ),
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 750,
                            columns: const [
                              DataColumn2(
                                  label: Text('Usuario Responsable', style: TextStyle(fontWeight: FontWeight.bold)),
                                  size: ColumnSize.L),
                              DataColumn2(
                                  label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
                                  size: ColumnSize.M),
                              DataColumn2(
                                  label: Text('Acción Realizada', style: TextStyle(fontWeight: FontWeight.bold)),
                                  size: ColumnSize.L),
                              DataColumn2(
                                  label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold)),
                                  size: ColumnSize.M),
                            ],
                            rows: _filteredLogs.map((log) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.indigo),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            log.user,
                                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Chip(
                                      backgroundColor: log.role.trim().toLowerCase().contains('admin') ? Colors.red.shade50 : Colors.blue.shade50,
                                      side: BorderSide(color: log.role.trim().toLowerCase().contains('admin') ? Colors.red.shade100 : Colors.blue.shade100),
                                      label: Text(
                                        log.role,
                                        style: TextStyle(
                                          color: log.role.trim().toLowerCase().contains('admin') ? Colors.red.shade700 : Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  DataCell(Text(log.action, style: const TextStyle(color: Colors.black87))),
                                  DataCell(
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dateTime),
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          );
        },
      ),
    );
  }
}
