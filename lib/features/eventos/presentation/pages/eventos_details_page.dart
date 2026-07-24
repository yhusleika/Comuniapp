import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, ByteData, rootBundle;
import 'package:dio/dio.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../domain/models/management_models.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../domain/repositories/eventos_repository.dart';
import '../../../../core/di/injection_container.dart';

class EventosDetailsPage extends StatefulWidget {
  final ManagementItem item;

  const EventosDetailsPage({super.key, required this.item});

  @override
  State<EventosDetailsPage> createState() => _EventosDetailsPageState();
}

class _EventosDetailsPageState extends State<EventosDetailsPage> {
  String _recordSearchQuery = '';
  final _recordSearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late List<Avance> _avances;
  late double _progress;
  late String _status;

  @override
  void initState() {
    super.initState();
    _avances = List.from(widget.item.avances);
    _progress = widget.item.progress;
    _status = widget.item.status;
  }

  @override
  void dispose() {
    _recordSearchController.dispose();
    super.dispose();
  }

  List<Avance> get _filteredAvances {
    if (_recordSearchQuery.isEmpty) return _avances;
    return _avances
        .where((a) =>
            a.descripcion.toLowerCase().contains(_recordSearchQuery.toLowerCase()))
        .toList();
  }

  String _resolveImagePath(String path) {
    if (path.startsWith('http') || path.startsWith('blob:') || path.startsWith('assets/') || path.startsWith('data:')) {
      return path;
    }
    try {
      final baseUrl = sl<MongoDBService>().dio.options.baseUrl;
      final uri = Uri.parse(baseUrl);
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '${uri.scheme}://${uri.host}:${uri.port}$cleanPath';
    } catch (e) {
      debugPrint('Error resolving image path $path: $e');
    }
    return path;
  }

  Future<Uint8List?> _getImageBytes(String path) async {
    try {
      if (path.startsWith('assets/')) {
        final ByteData data = await rootBundle.load(path);
        return data.buffer.asUint8List();
      }
      
      if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
        final resolvedPath = _resolveImagePath(path);
        final dio = Dio();
        final response = await dio.get<List<int>>(
          resolvedPath,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          return Uint8List.fromList(response.data!);
        }
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
      }
    } catch (e) {
      debugPrint('Error reading image bytes for $path: $e');
    }
    return null;
  }

  Future<void> _exportToExcel() async {
    if (_avances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay avances para exportar'), backgroundColor: Colors.orange),
      );
      return;
    }

    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['Avances'];

    // Header
    sheetObject.appendRow([
      TextCellValue('Nombre/Tipo'),
      TextCellValue('Progreso'),
      TextCellValue('Descripción/Observación'),
      TextCellValue('Fecha')
    ]);

    // Data
    for (var a in _avances) {
      sheetObject.appendRow([
        TextCellValue('Avance de Actividad'),
        TextCellValue('${(a.progress * 100).toInt()}%'),
        TextCellValue(a.descripcion),
        TextCellValue(DateFormat('yyyy-MM-dd').format(a.fecha))
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.save(
        'avances_${widget.item.name.replaceAll(' ', '_')}.xlsx',
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
    final pdf = pw.Document();
    
    // Load event photos
    final List<pw.Widget> mainPhotosWidgets = [];
    for (final path in widget.item.photos) {
      final bytes = await _getImageBytes(path);
      if (bytes != null) {
        mainPhotosWidgets.add(
          pw.Container(
            width: 150,
            height: 100,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
          ),
        );
      }
    }

    // Build advances timeline elements
    final List<pw.Widget> timelineWidgets = [];
    for (int i = 0; i < _avances.length; i++) {
      final av = _avances[i];
      final List<pw.Widget> avancePhotos = [];
      for (final p in av.fotos) {
        final bytes = await _getImageBytes(p);
        if (bytes != null) {
          avancePhotos.add(
            pw.Container(
              width: 80,
              height: 60,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
            ),
          );
        }
      }

      timelineWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Avance #${_avances.length - i}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo900)),
                  pw.Text(DateFormat('dd/MM/yyyy hh:mm a').format(av.fecha), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(av.descripcion, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900)),
              if (avancePhotos.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: avancePhotos,
                ),
              ],
            ],
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ALCALDÍA Y DESARROLLO COMUNITARIO', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                      pw.Text('SISTEMA GENERAL COMUNIAPP', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.indigo900),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reporte Individual de Actividad - Comuniapp', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Pág. ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          pw.Text('REPORTE DETALLADO DE EVENTO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 12),
          // Metadata Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Actividad: ${widget.item.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Categoría: ${widget.item.category}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Responsable: ${widget.item.responsible}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Estatus: ${widget.item.status}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.teal700)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Description
          pw.Text('Descripción General', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 6),
          pw.Text(widget.item.description.isNotEmpty ? widget.item.description : 'Sin descripción detallada.', style: const pw.TextStyle(fontSize: 10, height: 1.4)),
          pw.SizedBox(height: 16),

          // Main Photos
          if (mainPhotosWidgets.isNotEmpty) ...[
            pw.Text('Evidencia Fotográfica Principal', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mainPhotosWidgets,
            ),
            pw.SizedBox(height: 16),
          ],

          // Timeline / Avances
          pw.Text('Historial de Avances y Bitácoras', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 8),
          if (timelineWidgets.isEmpty)
            pw.Text('No se han registrado avances para esta actividad.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))
          else
            ...timelineWidgets,
        ],
      ),
    );

    final bytes = await pdf.save();
    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'reporte_${widget.item.name.replaceAll(' ', '_')}.pdf',
    );
  }

  void _confirmDeleteAvance(Avance avance, int index) {
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
            '¿Está seguro de que desea borrar este avance? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteAvance(index);
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

  void _deleteAvance(int index) async {
    setState(() {
      _avances.removeAt(index);
    });

    final newProgress = _avances.isNotEmpty ? _avances.first.progress : 0.0;
    String newStatus = 'En Proceso';
    if (newProgress >= 1.0) {
      newStatus = 'Completado';
    } else if (newProgress <= 0.0) {
      newStatus = 'Pendiente';
    }

    setState(() {
      _progress = newProgress;
      _status = newStatus;
    });

    final updatedItem = widget.item.copyWith(
      avances: _avances,
      progress: newProgress,
      status: newStatus,
    );

    final result = await sl<EventosRepository>().updateEvento(updatedItem);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar avance: ${failure.message}'), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avance eliminado con éxito'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado y Progreso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _status == 'Completado'
                        ? Colors.green.shade50
                        : _status == 'En Proceso'
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _status == 'Completado'
                          ? Colors.green
                          : _status == 'En Proceso'
                              ? Colors.blue
                              : Colors.orange,
                    ),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _status == 'Completado'
                          ? Colors.green.shade700
                          : _status == 'En Proceso'
                              ? Colors.blue.shade700
                              : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFF416FDF),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.black12),
            const SizedBox(height: 10),
            const Text(
              'Descripción de la Actividad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      item.description.isNotEmpty ? item.description : 'Sin descripción detallada.',
                      style: const TextStyle(color: Colors.black54, height: 1.4),
                    ),
                  ),
                ),
              ),
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
                          ? Image.network(_resolveImagePath(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                          : (path.startsWith('http') || path.startsWith('assets/'))
                              ? Image.network(_resolveImagePath(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
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

    final canCreateAvance = !isVisor && (isOperador || isAdmin);
    final canDeleteAvance = isAdmin;

    return CustomScaffold(
      floatingActionButton: canCreateAvance
          ? FloatingActionButton.extended(
              onPressed: _showAddAvanceDialog,
              icon: const Icon(Icons.add_task, color: Colors.white),
              label: const Text('Agregar Avance', style: TextStyle(color: Colors.white)),
              backgroundColor: theme.colorScheme.primary,
            )
          : null,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Header with circular buttons matching censos and ayudas
              _buildHeader(context, isVisor),

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
                    hintText: 'Filtrar avances...',
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
                            'Historial de Avances y Bitácora',
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
                                    label: Text('Tipo de Registro', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                                const DataColumn2(label: Text('Progreso', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
                                const DataColumn2(
                                    label: Text('Descripción / Detalles', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                                const DataColumn2(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                                if (canDeleteAvance)
                                  const DataColumn2(
                                    label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                                    size: ColumnSize.S,
                                    fixedWidth: 80,
                                  ),
                              ],
                              rows: _filteredAvances.asMap().entries
                                  .map((entry) {
                                        final index = entry.key;
                                        final a = entry.value;
                                        return DataRow(
                                          cells: [
                                            const DataCell(Text('Avance de Actividad', style: TextStyle(color: Colors.black87))),
                                            DataCell(Text('${(a.progress * 100).toInt()}%', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
                                            DataCell(Text(a.descripcion, style: const TextStyle(color: Colors.black87))),
                                            DataCell(
                                                Text(DateFormat('dd/MM/yyyy hh:mm a').format(a.fecha), style: const TextStyle(color: Colors.black87))),
                                            if (canDeleteAvance)
                                              DataCell(
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red, size: 20),
                                                  onPressed: () =>
                                                      _confirmDeleteAvance(a, index),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  tooltip: 'Borrar',
                                                ),
                                              ),
                                          ],
                                        );
                                  })
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
          ],
        ),
      ],
    );
  }

  void _showAddAvanceDialog() {
    final descriptionController = TextEditingController();
    List<XFile> selectedImages = [];
    bool isSaving = false;
    double progressValue = _progress;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
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
                          const Text(
                            'Agregar Avance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Descripción del Avance *',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: descriptionController,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Describa el progreso alcanzado...',
                                hintStyle: const TextStyle(color: Colors.black38),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Porcentaje de Finalización *',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            StatefulBuilder(
                              builder: (context, sliderSetState) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: progressValue,
                                        min: 0.0,
                                        max: 1.0,
                                        divisions: 20,
                                        activeColor: const Color(0xFF416FDF),
                                        inactiveColor: Colors.grey.shade200,
                                        onChanged: (v) {
                                          sliderSetState(() {
                                            progressValue = v;
                                          });
                                        },
                                      ),
                                    ),
                                    Text(
                                      '${(progressValue * 100).toInt()}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                                    ),
                                  ],
                                );
                              }
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Evidencia Fotográfica',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickMultiImage();
                                    if (picked.isNotEmpty) {
                                      dialogSetState(() {
                                        selectedImages.addAll(picked);
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Añadir Fotos'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (selectedImages.isNotEmpty)
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImages.length,
                                  itemBuilder: (context, idx) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 90,
                                          height: 90,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.black12),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: kIsWeb
                                              ? Image.network(selectedImages[idx].path, fit: BoxFit.cover)
                                              : Image.file(File(selectedImages[idx].path), fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 10,
                                          child: GestureDetector(
                                            onTap: () {
                                              dialogSetState(() {
                                                selectedImages.removeAt(idx);
                                              });
                                            },
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No se han seleccionado fotos',
                                    style: TextStyle(color: Colors.black38),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
                            onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF416FDF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final desc = descriptionController.text.trim();
                                    if (desc.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('La descripción es obligatoria'), backgroundColor: Colors.red),
                                      );
                                      return;
                                    }

                                    dialogSetState(() {
                                      isSaving = true;
                                    });

                                    final List<String> savedPaths = [];
                                    if (kIsWeb) {
                                      for (final img in selectedImages) {
                                        savedPaths.add(img.path);
                                      }
                                    } else {
                                      final compression = sl<ImageCompressionService>();
                                      for (final img in selectedImages) {
                                        final path = await compression.saveCompressedImage(File(img.path));
                                        savedPaths.add(path);
                                      }
                                    }

                                    final newAvance = Avance(
                                      descripcion: desc,
                                      fecha: DateTime.now(),
                                      fotos: savedPaths,
                                      progress: progressValue,
                                    );

                                    setState(() {
                                      _avances.insert(0, newAvance);
                                      _progress = progressValue;
                                    });

                                    String newStatus = 'En Proceso';
                                    if (progressValue >= 1.0) {
                                      newStatus = 'Completado';
                                    } else if (progressValue <= 0.0) {
                                      newStatus = 'Pendiente';
                                    }

                                    setState(() {
                                      _status = newStatus;
                                    });

                                    final updatedItem = widget.item.copyWith(
                                      avances: _avances,
                                      progress: progressValue,
                                      status: newStatus,
                                    );
                                    await sl<EventosRepository>().updateEvento(updatedItem);

                                    if (mounted) {
                                      Navigator.pop(dialogCtx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Avance agregado con éxito'), backgroundColor: Colors.green),
                                      );
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
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
      },
    );
  }
}
