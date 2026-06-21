import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../core/di/injection_container.dart';
import '../../../habitants/presentation/bloc/habitants_bloc.dart';
import '../../../habitants/domain/entities/habitante.dart';
import '../../domain/models/management_models.dart';
import '../widgets/management_form_modal.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/services/mongodb_service.dart';

class EventosPage extends StatelessWidget {
  const EventosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<HabitantsBloc>()..add(const LoadHabitants())),
      ],
      child: const EventosView(),
    );
  }
}

class EventosView extends StatefulWidget {
  const EventosView({super.key});

  @override
  State<EventosView> createState() => _EventosViewState();
}

class _EventosViewState extends State<EventosView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  String _selectedCategory = 'Eventos';
  String _searchQuery = '';
  String? _expandedItemId;
  bool _hasUnsavedChanges = false;

  // Controllers
  final _searchController = TextEditingController();

  // Mock Data replaced by remote fetching
  List<ManagementItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final service = sl<MongoDBService>();
      final remoteData = await service.getRecords('eventos');
      
      setState(() {
        _items = remoteData.map((json) => ManagementItem(
          id: json['id'],
          name: json['name'],
          date: DateTime.parse(json['date']),
          description: json['description'] ?? '',
          responsible: json['responsible'],
          category: json['category'],
          progress: (json['progress'] ?? 0.0).toDouble(),
          status: json['status'] ?? 'Pendiente',
          attendeeNames: List<String>.from(json['attendeeNames'] ?? []),
          photos: List<String>.from(json['photos'] ?? []),
        )).toList();
      });
    } catch (e) {
      debugPrint('Error loading eventos: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ManagementItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = item.category == _selectedCategory;
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.responsible.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _saveStatusChanges() async {
    final service = sl<MongoDBService>();
    for (final item in _items) {
      await service.updateRecord('eventos', item.id, {
        'status': item.status,
        'progress': item.progress,
      });
    }

    setState(() {
      _hasUnsavedChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios de estatus guardados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showManagementModal({ManagementItem? item}) {
    final habitantsState = context.read<HabitantsBloc>().state;
    final allHabitants = habitantsState is HabitantsLoaded ? habitantsState.habitants : <Habitante>[];

    showDialog(
      context: context,
      builder: (_) => ManagementFormModal(
        item: item,
        category: _selectedCategory,
        allHabitants: allHabitants,
        onSave: (savedItem) async {
          final service = sl<MongoDBService>();
          final Map<String, dynamic> data = {
            'id': savedItem.id,
            'name': savedItem.name,
            'date': savedItem.date.toIso8601String(),
            'description': savedItem.description,
            'responsible': savedItem.responsible,
            'category': savedItem.category,
            'progress': savedItem.progress,
            'status': savedItem.status,
            'attendeeNames': savedItem.attendeeNames,
            'photos': savedItem.photos,
          };

          if (item != null) {
            await service.updateRecord('eventos', savedItem.id, data);
            setState(() {
              final index = _items.indexWhere((i) => i.id == item.id);
              if (index != -1) _items[index] = savedItem;
            });
          } else {
            await service.createRecord('eventos', data);
            setState(() {
              _items.insert(0, savedItem);
            });
          }
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(item != null
                    ? '$_selectedCategory actualizado correctamente'
                    : '$_selectedCategory creado con éxito'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteItem(ManagementItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Item', style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: Text(
          '¿Está seguro de que desea eliminar "${item.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final service = sl<MongoDBService>();
              await service.deleteRecord('eventos', item.id);

              setState(() {
                _items.removeWhere((i) => i.id == item.id);
                if (_expandedItemId == item.id) {
                  _expandedItemId = null;
                }
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${item.name}" eliminado correctamente'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    final list = _filteredItems;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay $_selectedCategory para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final excel = Excel.createExcel();
    final Sheet sheet = excel['$_selectedCategory'];

    // Header
    sheet.appendRow([
      TextCellValue('Nombre'),
      TextCellValue('Fecha'),
      TextCellValue('Responsable'),
      TextCellValue('Progreso'),
      TextCellValue('Estatus'),
      TextCellValue('Descripción'),
    ]);

    for (final item in list) {
      sheet.appendRow([
        TextCellValue(item.name),
        TextCellValue(DateFormat('yyyy-MM-dd').format(item.date)),
        TextCellValue(item.responsible),
        DoubleCellValue(item.progress),
        TextCellValue(item.status),
        TextCellValue(item.description),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.save(
        '${_selectedCategory.toLowerCase()}_report.xlsx',
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
    final list = _filteredItems;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay $_selectedCategory para exportar'),
          backgroundColor: Colors.orange,
        ),
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
                pw.Text('Reporte de $_selectedCategory',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('Total: ${list.length}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: ['Nombre', 'Fecha', 'Responsable', 'Progreso', 'Estatus'],
            data: list.map((item) => [
              item.name,
              DateFormat('yyyy-MM-dd').format(item.date),
              item.responsible,
              '${(item.progress * 100).toInt()}%',
              item.status,
            ]).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo50),
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
      name: '${_selectedCategory.toLowerCase()}_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isAuditor = authState is AuthAuthenticated && authState.user.role.toLowerCase() == 'auditor';

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      floatingActionButton: _hasUnsavedChanges && !isAuditor
          ? FloatingActionButton.extended(
              onPressed: _saveStatusChanges,
              backgroundColor: theme.colorScheme.secondary,
              label: const Text('Actualizar Estatus',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.save),
            )
          : null,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Responsive Header (unifying colors)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeader(context, isAuditor),
            ),

            // Navigation Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: ['Eventos', 'Proyectos', 'Jornadas'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ElevatedButton(
                    onPressed: () => setState(() {
                      _selectedCategory = cat;
                      _expandedItemId = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white,
                      foregroundColor: isSelected
                          ? Colors.white
                          : Colors.black87,
                      elevation: isSelected ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.black12,
                        ),
                      ),
                    ),
                    child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o responsable...',
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
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

            const SizedBox(height: 16),

            // List of Items
            _buildListView(theme, isAuditor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAuditor) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Actividades',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Administra $_selectedCategory de tu comunidad',
              style: const TextStyle(
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
            // PDF Export Button
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
              // Add Button (Circular and Premium)
              Tooltip(
                message: 'Nuevo $_selectedCategory',
                child: IconButton(
                  onPressed: () => _showManagementModal(),
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

  Widget _buildListView(ThemeData theme, bool isAuditor) {
    final list = _filteredItems;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_note, size: 60, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No se encontraron $_selectedCategory',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isExpanded = _expandedItemId == item.id;

        return Card(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black12),
          ),
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          backgroundColor: Colors.grey[200],
                          color: theme.colorScheme.primary,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(item.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Resp: ${item.responsible} • ${DateFormat('dd/MM/yyyy').format(item.date)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.black54,
                ),
                onTap: () => setState(
                  () => _expandedItemId = isExpanded ? null : item.id,
                ),
              ),
              if (isExpanded) _buildExpandedForm(item, theme, isAuditor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedForm(ManagementItem item, ThemeData theme, bool isAuditor) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Estatus:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              isAuditor
                  ? Text(
                      item.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.status == 'Completado'
                            ? Colors.green
                            : item.status == 'En Proceso'
                                ? Colors.blue
                                : Colors.orange,
                      ),
                    )
                  : DropdownButton<String>(
                      dropdownColor: Colors.white,
                      value: item.status,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      underline: Container(
                        height: 2,
                        color: theme.colorScheme.primary,
                      ),
                      items: ['Pendiente', 'En Proceso', 'Completado'].map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != item.status) {
                          setState(() {
                            final idx = _items.indexWhere((i) => i.id == item.id);
                            if (idx != -1) {
                              double newProg = item.progress;
                              if (val == 'Completado') newProg = 1.0;
                              if (val == 'Pendiente') newProg = 0.0;
                              _items[idx] = item.copyWith(status: val, progress: newProg);
                              _hasUnsavedChanges = true;
                            }
                          });
                        }
                      },
                    ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Descripción:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            item.description.isNotEmpty ? item.description : 'Sin descripción detallada.',
            style: const TextStyle(color: Colors.black54),
          ),
          if (item.attendeeNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Asistentes/Beneficiarios:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.attendeeNames.map((name) => Chip(
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade100),
                label: Text(name, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
          if (item.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Evidencia Fotográfica:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: item.photos.length,
                itemBuilder: (context, index) {
                  final path = item.photos[index];
                  return Container(
                    width: 100,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
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
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/eventos/details', extra: item),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Ver Datos'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(14)),
                      ),
                    ),
                    if (!isAuditor) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showManagementModal(item: item),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(14)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmDeleteItem(item),
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(14)),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/eventos/details', extra: item),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Ver Datos'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white),
                      ),
                    ),
                    if (!isAuditor) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showManagementModal(item: item),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmDeleteItem(item),
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}
