import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../habitants/presentation/bloc/habitants_bloc.dart';
import '../../../habitants/domain/entities/habitante.dart';
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
  const CensosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CensosBloc>()..add(LoadCensos())),
        BlocProvider(create: (_) => sl<HabitantsBloc>()..add(const LoadHabitants())),
      ],
      child: ChangeNotifierProvider(
        create: (_) => CensosNotifier(),
        child: const CensosView(),
      ),
    );
  }
}

class CensosView extends StatefulWidget {
  const CensosView({super.key});

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
    final isAuditor = authState is AuthAuthenticated && authState.user.role.toLowerCase() == 'auditor';

    return CustomScaffold(
      scaffoldKey: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: BlocListener<CensosBloc, CensosState>(
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
              _buildHeader(context, isAuditor),
              const SizedBox(height: 20),
              _buildCensoSelectorSection(context),
              const SizedBox(height: 20),
              _buildFilters(context),
              const SizedBox(height: 20),
              if (_notifier!.selectedCenso != null)
                _buildTable(context, isAuditor)
              else
                const Center(
                    child: Text('Cree un censo para comenzar',
                        style: TextStyle(color: Colors.white70, fontSize: 18))),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isAuditor) {
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
        // Botón circular + (solo si no es auditor)
        if (!isAuditor)
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

  Widget _buildCensoSelectorSection(BuildContext context) {
    final censos = _notifier!.censos;
    if (censos.isEmpty) return const SizedBox.shrink();

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
          height: 110,
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
                  width: 220,
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
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Zona: ${c.zona}',
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
                  const SizedBox(width: 8),
                  // PDF
                  Tooltip(
                    message: 'Exportar Censo a PDF',
                    child: IconButton(
                      onPressed: _exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf,
                          color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
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

  Widget _buildTable(BuildContext context, bool isAuditor) {
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
                // Botón circular + para agregar registro (solo si no es auditor)
                if (!isAuditor)
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
              cardTheme: CardTheme(
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
                    const DataColumn(label: Text('Jefe de Familia')),
                    const DataColumn(label: Text('Cédula')),
                    const DataColumn(label: Text('Dirección')),
                    if (!isAuditor) const DataColumn(label: Text('Acciones')),
                  ],
                  source: FamilyRecordsDataTableSource(
                    records: _notifier!.filteredRecords,
                    context: context,
                    onEdit: (r) => _showRecordModal(record: r),
                    onDelete: (r) => _confirmDelete(r),
                    isAuditor: isAuditor,
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

  // ─── Exportar a PDF ────────────────────────────────────────────────────────

  Future<void> _exportToPDF() async {
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

    final activeFields = CensoDictionary.fields
        .where((f) => censo.camposSeleccionados.contains(f.id))
        .toList();
    final personasFields = activeFields.where((f) => f.category == 'Datos de Personas').toList();
    final householdFields = activeFields.where((f) => f.category != 'Datos de Personas').toList();

    final headers = [
      ...householdFields.map((f) => f.label),
      ...personasFields.map((f) => f.label),
      'Estatus'
    ];

    final List<List<String>> data = [];
    for (final r in records) {
      final list = r.datosDinamicos['familiares'] as List? ?? [];
      if (list.isEmpty) {
        final row = <String>[];
        for (final f in householdFields) {
          row.add(_formatValue(r.datosDinamicos[f.id]));
        }
        for (final f in personasFields) {
          if (f.id == 'jefeFamilia') {
            row.add(r.jefeFamilia);
          } else if (f.id == 'cedula') {
            row.add(r.cedula);
          } else {
            row.add('');
          }
        }
        row.add(r.estatus);
        data.add(row);
      } else {
        for (final m in list) {
          final row = <String>[];
          for (final f in householdFields) {
            row.add(_formatValue(r.datosDinamicos[f.id]));
          }
          for (final f in personasFields) {
            row.add(_formatValue(m[f.id]));
          }
          row.add(r.estatus);
          data.add(row);
        }
      }
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Reporte Censo Completo: ${censo.nombre}',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Zona: ${censo.zona}  •  Responsable: ${censo.responsable}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 7),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: const pw.TextStyle(fontSize: 6),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.teal50),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'censo_${censo.nombre}.pdf',
    );
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
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CensoRecordFormModal(
          censo: _notifier!.selectedCenso!,
          record: record,
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
}
