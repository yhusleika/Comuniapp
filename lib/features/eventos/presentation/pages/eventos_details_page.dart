import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../domain/models/management_models.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class EventosDetailsPage extends StatefulWidget {
  final ManagementItem item;

  const EventosDetailsPage({super.key, required this.item});

  @override
  State<EventosDetailsPage> createState() => _EventosDetailsPageState();
}

class _EventosDetailsPageState extends State<EventosDetailsPage> {
  late List<ManagementRecord> _records;
  String _recordSearchQuery = '';
  final _recordSearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Mock records for the item
    _records = List.generate(
        10,
        (i) => ManagementRecord(
              id: i.toString(),
              itemId: widget.item.id,
              field1: i % 2 == 0 ? 'Suministros Norte' : 'Base Regional',
              field2: (150 * (i + 1)).toString(),
              field3: 'Nota técnica $i',
              date: DateTime.now().subtract(Duration(days: i)),
            ));
  }

  @override
  void dispose() {
    _recordSearchController.dispose();
    super.dispose();
  }

  List<ManagementRecord> get _filteredRecords {
    if (_recordSearchQuery.isEmpty) return _records;
    return _records
        .where((r) =>
            r.field1.toLowerCase().contains(_recordSearchQuery.toLowerCase()) ||
            r.field2.toLowerCase().contains(_recordSearchQuery.toLowerCase()) ||
            r.field3.toLowerCase().contains(_recordSearchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _exportToExcel() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para exportar'), backgroundColor: Colors.orange),
      );
      return;
    }

    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Registros'];

    // Header
    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Lugar/Nombre'),
      TextCellValue('Cantidad/Valor'),
      TextCellValue('Observación'),
      TextCellValue('Fecha')
    ]);

    // Data
    for (var record in _records) {
      sheetObject.appendRow([
        TextCellValue(record.id),
        TextCellValue(record.field1),
        TextCellValue(record.field2),
        TextCellValue(record.field3),
        TextCellValue(DateFormat('yyyy-MM-dd').format(record.date))
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.save(
        'registros_${widget.item.name.replaceAll(' ', '_')}.xlsx',
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

  Future<void> _exportToPDF() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para exportar'), backgroundColor: Colors.orange),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Registros de ${widget.item.name}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Total: ${_records.length}',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Categoría: ${widget.item.category} • Responsable: ${widget.item.responsible}',
              style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Lugar/Nombre', 'Valor/Cantidad', 'Observación', 'Fecha'],
            data: _records.map((r) => [
              r.id,
              r.field1,
              r.field2,
              r.field3,
              DateFormat('yyyy-MM-dd').format(r.date),
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.teal50),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'registros_${widget.item.name.replaceAll(' ', '_')}.pdf',
    );
  }

  void _showAddEditRecordDialog({ManagementRecord? record}) {
    final isEditing = record != null;
    final c1 = TextEditingController(text: record?.field1 ?? '');
    final c2 = TextEditingController(text: record?.field2 ?? '');
    final c3 = TextEditingController(text: record?.field3 ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          elevation: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF416FDF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Editar Registro' : 'Incluir Nuevo Dato',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Form content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lugar / Nombre del Registro *',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: c1,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Ej. Sector Norte o Materiales',
                            hintStyle: const TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Cantidad / Valor *',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: c2,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Ej. 150 o Completado',
                            hintStyle: const TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Observación / Comentario',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: c3,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Detalles adicionales...',
                            hintStyle: const TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF416FDF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              if (isEditing) {
                                final index = _records.indexWhere((r) => r.id == record.id);
                                if (index != -1) {
                                  _records[index] = record.copyWith(
                                      field1: c1.text.trim(), field2: c2.text.trim(), field3: c3.text.trim());
                                }
                              } else {
                                _records.insert(
                                    0,
                                    ManagementRecord(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      itemId: widget.item.id,
                                      field1: c1.text.trim(),
                                      field2: c2.text.trim(),
                                      field3: c3.text.trim(),
                                      date: DateTime.now(),
                                    ));
                              }
                            });
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteRecord(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('¿Confirmar Eliminación?', style: TextStyle(color: Colors.black87)),
            ],
          ),
          content: const Text(
            '¿Está seguro de que desea borrar este registro? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _performDelete(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  void _performDelete(String id) {
    setState(() {
      _records.removeWhere((r) => r.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro eliminado con éxito'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final item = widget.item;

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción de la Actividad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description.isNotEmpty ? item.description : 'Sin descripción detallada.',
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
            if (item.photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Evidencia Fotográfica',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.photos.length,
                  itemBuilder: (context, index) {
                    final path = item.photos[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: kIsWeb
                          ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                          : (path.startsWith('http') || path.startsWith('assets/'))
                              ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                              : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isAuditor = authState is AuthAuthenticated && authState.user.role.toLowerCase() == 'auditor';

    return CustomScaffold(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Header with circular buttons matching censos and ayudas
              _buildHeader(context, isAuditor),

              const SizedBox(height: 20),

              // Summary Card
              _buildSummaryCard(theme),

              const SizedBox(height: 24),

              // Record Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _recordSearchController,
                  onChanged: (val) => setState(() => _recordSearchQuery = val),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Filtrar registros...',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Data Table with Margin/Padding in a unified white card layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Colors.black12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Historial de Registros',
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
                              minWidth: 700,
                              columns: [
                                const DataColumn2(
                                    label: Text('Lugar/Nombre', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                                const DataColumn2(label: Text('Valor/Cantidad', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                                const DataColumn2(
                                    label: Text('Observación', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                                const DataColumn2(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                                if (!isAuditor)
                                  const DataColumn2(
                                    label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                                    size: ColumnSize.M,
                                    fixedWidth: 100,
                                  ),
                              ],
                              rows: _filteredRecords
                                  .map((r) => DataRow(
                                        cells: [
                                          DataCell(Text(r.field1, style: const TextStyle(color: Colors.black87))),
                                          DataCell(Text(r.field2, style: const TextStyle(color: Colors.black87))),
                                          DataCell(Text(r.field3, style: const TextStyle(color: Colors.black87))),
                                          DataCell(
                                              Text(DateFormat('dd/MM/yyyy').format(r.date), style: const TextStyle(color: Colors.black87))),
                                          if (!isAuditor)
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blue, size: 20),
                                                    onPressed: () =>
                                                        _showAddEditRecordDialog(record: r),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    tooltip: 'Editar',
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete,
                                                        color: Colors.red, size: 20),
                                                    onPressed: () =>
                                                        _confirmDeleteRecord(r.id),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    tooltip: 'Borrar',
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAuditor) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Detalles del registro de ${widget.item.category.toLowerCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Excel Export
            Tooltip(
              message: 'Exportar a Excel',
              child: IconButton(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.table_view, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.all(10),
                  elevation: 2,
                  shape: const CircleBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // PDF Export
            Tooltip(
              message: 'Exportar a PDF',
              child: IconButton(
                onPressed: _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.all(10),
                  elevation: 2,
                  shape: const CircleBorder(),
                ),
              ),
            ),
            if (!isAuditor) ...[
              const SizedBox(width: 8),
              // Add Record Button
              Tooltip(
                message: 'Incluir Nuevo Dato',
                child: IconButton(
                  onPressed: () => _showAddEditRecordDialog(),
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
          ],
        ),
      ],
    );
  }
}
