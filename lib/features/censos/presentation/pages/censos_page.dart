import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' hide Border;
import '../../../../core/utils/file_saver.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../habitantes/presentation/bloc/habitants_bloc.dart';
import '../../../habitantes/domain/entities/habitante.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/censos_bloc.dart';
import '../bloc/censos_event.dart';
import '../bloc/censos_state.dart';
import '../providers/censos_notifier.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';
import '../../domain/entities/censo_fields_dictionary.dart';
import '../widgets/censo_form_builder_modal.dart';
import '../widgets/censo_record_form_modal.dart';

class CensosPage extends StatelessWidget {
  final bool embedded;
  const CensosPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CensosBloc>()..add(LoadCensos())),
        BlocProvider(create: (_) => sl<HabitantsBloc>()..add(const LoadHabitants())),
      ],
      child: ChangeNotifierProvider(
        create: (_) => CensosNotifier(),
        child: CensosView(embedded: embedded),
      ),
    );
  }
}

class CensosView extends StatefulWidget {
  final bool embedded;
  const CensosView({super.key, this.embedded = false});

  @override
  State<CensosView> createState() => _CensosViewState();
}

class _CensosViewState extends State<CensosView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  CensosNotifier? _notifier;

  @override
  Widget build(BuildContext context) {
    _notifier = Provider.of<CensosNotifier>(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final userRole = (user?.role ?? '').toLowerCase().trim();
    final username = (user?.username ?? '').toLowerCase().trim();

    final isVisor = userRole.contains('visor') ||
        userRole.contains('auditor') ||
        username.contains('visor') ||
        username.contains('auditor') ||
        userRole.isEmpty;
    final isOperador = !isVisor && userRole.contains('operador');
    final isAdmin = !isVisor && (userRole.contains('admin') || userRole.contains('vocero') || username.contains('admin'));

    final canCreate = !isVisor && (isOperador || isAdmin);
    final canEdit = !isVisor && (isOperador || isAdmin);
    final canDelete = isAdmin;

    final body = BlocListener<CensosBloc, CensosState>(
        listener: (context, state) {
          if (state is CensosLoaded) {
            final oldLen = _notifier!.censos.length;
            _notifier!.updateCensos(state.censos);
            if (state.censos.length > oldLen) {
              _notifier!.selectCenso(state.censos.last);
            }
            if (_notifier!.selectedCenso != null) {
              context
                  .read<CensosBloc>()
                  .add(LoadCensoRecords(_notifier!.selectedCenso!.id));
            }
          } else if (state is CensoRecordsLoaded) {
            _notifier!.updateRecords(state.records);
          } else if (state is CensoOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Operación exitosa'),
                  backgroundColor: Colors.green),
            );
          } else if (state is CensoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, canCreate),
              const SizedBox(height: 20),
              _buildCensoSelectorSection(context, canDelete),
              const SizedBox(height: 20),
              _buildFilters(context),
              const SizedBox(height: 20),
              if (_notifier!.selectedCenso != null)
                _buildTable(context, canCreate, canEdit, canDelete)
              else
                const Center(
                    child: Text('Cree un censo para comenzar',
                        style: TextStyle(color: Colors.white70, fontSize: 18))),
            ],
          ),
        ),
    );

    if (widget.embedded) return body;
    return CustomScaffold(
      scaffoldKey: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: body,
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool canCreate) {
    final theme = Theme.of(context);
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
              'Gestión de Censos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Consulta y administra los censos de la comunidad',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
        if (canCreate)
          Tooltip(
            message: 'Nuevo Censo',
            child: IconButton(
              onPressed: () => _showCensoModal(),
              icon: const Icon(Icons.add, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                elevation: 3,
                shadowColor: Colors.black38,
                shape: const CircleBorder(),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Selector por Tarjetas ──────────────────────────────────────────────────

  Widget _buildCensoSelectorSection(BuildContext context, bool canDelete) {
    final censos = _notifier!.censos;
    if (censos.isEmpty) return const SizedBox.shrink();

    final isAdmin = canDelete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Censos Disponibles',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: censos.length,
            itemBuilder: (context, index) {
              final c = censos[index];
              final isSelected = _notifier!.selectedCenso?.id == c.id;

              // Tailored colors for premium card look
              final colors = [
                Colors.indigo.shade600,
                Colors.teal.shade600,
                Colors.deepOrange.shade600,
                Colors.blue.shade700,
                Colors.purple.shade600,
              ];
              final cardColor = colors[index % colors.length];

              return GestureDetector(
                onTap: () {
                  _notifier!.selectCenso(c);
                  context.read<CensosBloc>().add(LoadCensoRecords(c.id));
                },
                child: Container(
                  width: 230,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    color: isSelected ? cardColor : cardColor.withOpacity(0.55),
                    elevation: isSelected ? 6 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(color: Colors.white, width: 2)
                          : BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  c.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _confirmDeleteCenso(context, c),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                    ]
                                  ],
                                )
                              else if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Sector: ${c.zona}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Resp: ${c.responsable}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Filtros ───────────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    _buildSearchField(context),
                    const SizedBox(height: 15),
                    _buildStatusDropdown(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: _buildSearchField(context)),
                    const SizedBox(width: 15),
                    Expanded(flex: 2, child: _buildStatusDropdown()),
                  ],
                ),
          const SizedBox(height: 15),
          // Fila de resultados + botones de exportación
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Text(
                'Resultados: ${_notifier!.filteredRecords.length}',
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Excel
                  Tooltip(
                    message: 'Exportar Censo a Excel',
                    child: IconButton(
                      onPressed: _exportToExcel,
                      icon:
                          const Icon(Icons.table_view, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.all(10),
                        elevation: 2,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.black87),
      onChanged: (v) => _notifier!.setSearchQuery(v),
      decoration: InputDecoration(
        hintText: 'Buscar jefe de familia o cédula...',
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon:
            Icon(Icons.search, color: Theme.of(context).primaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: _notifier!.statusFilter,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Estatus',
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: ['Todos', 'Censados', 'Pendientes', 'Casos Especiales']
          .map((s) => DropdownMenuItem(
              value: s,
              child:
                  Text(s, style: const TextStyle(color: Colors.black87))))
          .toList(),
      onChanged: (v) => _notifier!.setStatusFilter(v!),
    );
  }

  // ─── Tabla ────────────────────────────────────────────────────────────────

  Widget _buildTable(BuildContext context, bool canCreate, bool canEdit, bool canDelete) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registros de Familia',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                if (canCreate)
                  Tooltip(
                    message: 'Agregar Registro',
                    child: IconButton(
                      onPressed: () => _showRecordModal(),
                      icon: const Icon(Icons.add, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(10),
                        elevation: 2,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Theme(
            data: theme.copyWith(
              cardColor: Colors.white,
              cardTheme: CardThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              colorScheme: theme.colorScheme.copyWith(
                surface: Colors.white,
              ),
              dividerColor: Colors.grey.shade200,
              textTheme: theme.textTheme.apply(
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width > 832
                      ? MediaQuery.of(context).size.width - 32
                      : 800,
                  maxWidth: MediaQuery.of(context).size.width > 832
                      ? MediaQuery.of(context).size.width - 32
                      : 800,
                ),
                child: PaginatedDataTable(
                  header: null,
                  rowsPerPage: 10,
                  showFirstLastButtons: true,
                  columns: [
                    const DataColumn(label: Text('Nº')),
                    const DataColumn(label: Text('Jefe de Familia')),
                    const DataColumn(label: Text('Cédula')),
                    const DataColumn(label: Text('Dirección')),
                    if (canEdit || canDelete) const DataColumn(label: Text('Acciones')),
                  ],
                  source: FamilyRecordsDataTableSource(
                    records: _notifier!.filteredRecords,
                    context: context,
                    onEdit: (r) => _showRecordModal(record: r),
                    onDelete: (r) => _confirmDelete(r),
                    canEdit: canEdit,
                    canDelete: canDelete,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format values for exports
  String _formatValue(dynamic val) {
    if (val == null) return '';
    if (val is List) return val.join(', ');
    if (val is Map) {
      return val.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return val.toString();
  }

  // ─── Exportar a Excel ──────────────────────────────────────────────────────

  Future<void> _exportToExcel() async {
    final records = _notifier!.filteredRecords;
    final censo = _notifier!.selectedCenso;
    if (records.isEmpty || censo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay registros para exportar'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final excelFile = Excel.createExcel();
    final Sheet sheet = excelFile['Censo - ${censo.nombre}'];

    // Get selected fields and split by category
    final activeFields = CensoDictionary.fields
        .where((f) => censo.camposSeleccionados.contains(f.id))
        .toList();
    final personasFields = activeFields.where((f) => f.category == 'Datos de Personas').toList();
    final householdFields = activeFields.where((f) => f.category != 'Datos de Personas').toList();

    // Headers
    final List<CellValue> headers = [
      ...householdFields.map((f) => TextCellValue(f.label)),
      ...personasFields.map((f) => TextCellValue(f.label)),
      TextCellValue('Estatus del Censo'),
    ];
    sheet.appendRow(headers);

    for (final r in records) {
      final list = r.datosDinamicos['familiares'] as List? ?? [];
      if (list.isEmpty) {
        final row = <CellValue>[];
        for (final f in householdFields) {
          row.add(TextCellValue(_formatValue(r.datosDinamicos[f.id])));
        }
        for (final f in personasFields) {
          if (f.id == 'jefeFamilia') {
            row.add(TextCellValue(r.jefeFamilia));
          } else if (f.id == 'cedula') {
            row.add(TextCellValue(r.cedula));
          } else {
            row.add(TextCellValue(''));
          }
        }
        row.add(TextCellValue(r.estatus));
        sheet.appendRow(row);
      } else {
        for (final m in list) {
          final row = <CellValue>[];
          for (final f in householdFields) {
            row.add(TextCellValue(_formatValue(r.datosDinamicos[f.id])));
          }
          for (final f in personasFields) {
            row.add(TextCellValue(_formatValue(m[f.id])));
          }
          row.add(TextCellValue(r.estatus));
          sheet.appendRow(row);
        }
      }
    }

    final fileBytes = excelFile.save();
    if (fileBytes != null) {
      await FileSaver.save(
        'censo_${censo.nombre.replaceAll(' ', '_')}.xlsx',
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



  // ─── Acciones ─────────────────────────────────────────────────────────────

  void _showCensoModal() {
    final censosBloc = context.read<CensosBloc>();
    final habitantsState = context.read<HabitantsBloc>().state;
    final allHabitants = habitantsState is HabitantsLoaded ? habitantsState.habitants : <Habitante>[];

    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: censosBloc),
        ],
        child: CensoFormBuilderModal(allHabitants: allHabitants),
      ),
    );
  }

  void _showRecordModal({CensoRecord? record}) {
    final bloc = context.read<CensosBloc>();
    final habitantsBloc = context.read<HabitantsBloc>();
    final habitantsState = habitantsBloc.state;
    debugPrint('CensosPage: _showRecordModal - habitantsState is $habitantsState');
    final allHabitants = habitantsState is HabitantsLoaded ? habitantsState.habitants : <Habitante>[];
    debugPrint('CensosPage: _showRecordModal - allHabitants count: ${allHabitants.length}');

    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: habitantsBloc),
        ],
        child: CensoRecordFormModal(
          censo: _notifier!.selectedCenso!,
          record: record,
          nextNumEncuesta: _notifier!.records.length + 1,
          allHabitants: allHabitants,
        ),
      ),
    );
  }

  void _confirmDelete(CensoRecord record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Registro',
                style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: Text(
            '¿Está seguro de eliminar el registro de ${record.jefeFamilia}?',
            style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context
                  .read<CensosBloc>()
                  .add(DeleteCensoRecordEvent(record.id));
              context
                  .read<CensosBloc>()
                  .add(LoadCensoRecords(record.censoId));
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCenso(BuildContext context, Censo censo) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Censo', style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: Text(
          '¿Está seguro de eliminar el censo "${censo.nombre}" y todos sus registros de forma permanente?',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CensosBloc>().add(DeleteCensoEvent(id: censo.id, nombre: censo.nombre));
              Navigator.pop(dialogCtx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
