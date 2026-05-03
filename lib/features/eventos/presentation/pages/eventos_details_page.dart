import 'dart:io';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/management_models.dart';
import '../../../../shared/widgets/custom_scaffold.dart';

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
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Header
    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Campo 1'),
      TextCellValue('Campo 2'),
      TextCellValue('Campo 3'),
      TextCellValue('Fecha')
    ]);

    // Data
    for (var record in _records) {
      sheetObject.appendRow([
        TextCellValue(record.id),
        TextCellValue(record.field1),
        TextCellValue(record.field2),
        TextCellValue(record.field3),
        TextCellValue(record.date.toString())
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'reporte_${widget.item.name.replaceAll(' ', '_')}.xlsx';
    final file = File('${directory.path}/$fileName');

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel exportado a: ${file.path}')),
        );
      }
    }
  }

  void _showAddEditRecordDialog({ManagementRecord? record}) {
    final isEditing = record != null;
    final c1 = TextEditingController(text: record?.field1 ?? '');
    final c2 = TextEditingController(text: record?.field2 ?? '');
    final c3 = TextEditingController(text: record?.field3 ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Registro' : 'Incluir Nuevo Dato'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: c1,
                    decoration: const InputDecoration(
                      labelText: 'Campo 1 (Nombre/Lugar)',
                      border: OutlineInputBorder(),
                    )),
                const SizedBox(height: 16),
                TextField(
                    controller: c2,
                    decoration: const InputDecoration(
                      labelText: 'Campo 2 (Cantidad/Valor)',
                      border: OutlineInputBorder(),
                    )),
                const SizedBox(height: 16),
                TextField(
                    controller: c3,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Campo 3 (Observación)',
                      border: OutlineInputBorder(),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    final index = _records.indexWhere((r) => r.id == record.id);
                    _records[index] = record.copyWith(
                        field1: c1.text, field2: c2.text, field3: c3.text);
                  } else {
                    _records.insert(
                        0,
                        ManagementRecord(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          itemId: widget.item.id,
                          field1: c1.text,
                          field2: c2.text,
                          field3: c3.text,
                          date: DateTime.now(),
                        ));
                  }
                });
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Actualizar' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteRecord(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Confirmar Eliminación?'),
          content: const Text(
              '¿Está seguro de que desea borrar este registro? Esta acción no se puede deshacer.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Responsive Header (Wrap)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Detalles: ${widget.item.name}',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditRecordDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Incluir Datos'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar a Excel'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Record Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _recordSearchController,
                onChanged: (val) => setState(() => _recordSearchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Filtrar registros...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.filter_list, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data Table with Margin/Padding
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 900,
                    columns: const [
                      DataColumn2(
                          label: Text('Lugar/Nombre'), size: ColumnSize.L),
                      DataColumn2(label: Text('Valor'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Observación'), size: ColumnSize.L),
                      DataColumn2(label: Text('Fecha'), size: ColumnSize.M),
                      DataColumn2(
                        label: Text('Acciones'),
                        size: ColumnSize.M,
                        fixedWidth: 120,
                      ),
                    ],
                    rows: _filteredRecords
                        .map((r) => DataRow(
                              cells: [
                                DataCell(Text(r.field1)),
                                DataCell(Text(r.field2)),
                                DataCell(Text(r.field3)),
                                DataCell(
                                    Text(r.date.toString().substring(0, 10))),
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
            ),
          ],
        ),
      ),
    );
  }
}
