import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../bloc/habitants_bloc.dart';
import '../providers/habitants_notifier.dart';
import '../../domain/entities/habitante.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class HabitantsPage extends StatelessWidget {
  const HabitantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HabitantsBloc>()..add(const LoadHabitants()),
      child: const HabitantsView(),
    );
  }
}

class HabitantsView extends StatefulWidget {
  const HabitantsView({super.key});

  @override
  State<HabitantsView> createState() => _HabitantsViewState();
}

class _HabitantsViewState extends State<HabitantsView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  HabitantsNotifier? _notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isAuditor = authState is AuthAuthenticated && authState.user.role.toLowerCase() == 'auditor';

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: BlocListener<HabitantsBloc, HabitantsState>(
        listener: (context, state) {
          if (state is HabitantsLoaded) {
            setState(() {
              _notifier = HabitantsNotifier(state.habitants, isAuditor: isAuditor);
            });
          }
          if (state is HabitanteOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Operación realizada con éxito'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is HabitantsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _notifier == null
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: _notifier!,
                builder: (context, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(theme, isAuditor),
                        const SizedBox(height: 20),
                        _buildFilters(theme),
                        const SizedBox(height: 20),
                        _buildDataTable(theme, isAuditor),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isAuditor) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Text(
          'Beneficiarios Activos',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Excel
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
            // PDF
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
              // Agregar
              Tooltip(
                message: 'Agregar Habitante',
                child: IconButton(
                  onPressed: () => _showHabitanteModal(),
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

  // ─── Filtros ───────────────────────────────────────────────────────────────

  Widget _buildFilters(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _notifier!.updateSearch,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o cédula...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _notifier!.selectedZone,
                    decoration: const InputDecoration(
                        labelText: 'Zona', border: OutlineInputBorder()),
                    items: ['Todas', 'Zona A', 'Zona B', 'Zona C', 'Zona D']
                        .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                        .toList(),
                    onChanged: _notifier!.updateZone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _notifier!.selectedAid,
                    decoration: const InputDecoration(
                        labelText: 'Ayuda Recibida',
                        border: OutlineInputBorder()),
                    items: [
                      'Todas',
                      'Alimentación',
                      'Medicinas',
                      'Vivienda',
                      'Ninguna'
                    ]
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: _notifier!.updateAid,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tabla ────────────────────────────────────────────────────────────────

  Widget _buildDataTable(ThemeData theme, bool isAuditor) {
    final ds = _notifier!.dataSource;
    ds.onEdit = (h) => _showHabitanteModal(habitante: h);
    ds.onDelete = _confirmDelete;

    return Theme(
      data: theme.copyWith(
        cardColor: Colors.white,
        dividerColor: Colors.grey[200],
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
            header: const Text('Listado de Habitantes'),
            rowsPerPage: _notifier!.filteredHabitants.length > 10
                ? 10
                : (_notifier!.filteredHabitants.isEmpty
                    ? 1
                    : _notifier!.filteredHabitants.length),
            availableRowsPerPage: const [10, 25, 50, 100],
            columns: [
              const DataColumn(label: Text('Nombre')),
              const DataColumn(label: Text('Apellido')),
              const DataColumn(label: Text('Cédula')),
              const DataColumn(label: Text('Zona')),
              const DataColumn(label: Text('Ayuda')),
              if (!isAuditor) const DataColumn(label: Text('Acciones')),
            ],
            source: ds,
          ),
        ),
      ),
    );
  }

  // ─── Modal Agregar / Editar ────────────────────────────────────────────────

  void _showHabitanteModal({Habitante? habitante}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _HabitanteFormDialog(
        habitante: habitante,
        onSave: (newHabitante) {
          if (habitante != null) {
            context.read<HabitantsBloc>().add(UpdateHabitanteEvent(newHabitante));
          } else {
            context.read<HabitantsBloc>().add(CreateHabitante(newHabitante));
          }
        },
      ),
    );
  }

  // ─── Confirmar Eliminar ────────────────────────────────────────────────────

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('¿Confirmar Eliminación?'),
            ],
          ),
          content: const Text(
              '¿Está seguro de que desea borrar este habitante? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                context.read<HabitantsBloc>().add(DeleteHabitanteEvent(id));
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

  // ─── Exportar a Excel ──────────────────────────────────────────────────────

  Future<void> _exportToExcel() async {
    final list = _notifier!.filteredHabitants;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay habitantes para exportar')),
      );
      return;
    }

    final excelFile = Excel.createExcel();
    final Sheet sheet = excelFile['Habitantes'];

    // Encabezados
    sheet.appendRow([
      TextCellValue('Nombres'),
      TextCellValue('Apellidos'),
      TextCellValue('Cédula'),
      TextCellValue('Teléfono'),
      TextCellValue('Zona/Sector'),
      TextCellValue('Ayuda Recibida'),
      TextCellValue('Cond. Vivienda'),
      TextCellValue('Tipo Vivienda'),
      TextCellValue('Discapacidad'),
      TextCellValue('Enf. Crónica'),
      TextCellValue('Fecha Registro'),
    ]);

    // Datos
    for (var h in list) {
      sheet.appendRow([
        TextCellValue(h.nombres),
        TextCellValue(h.apellidos),
        TextCellValue(h.cedula),
        TextCellValue(h.telefono),
        TextCellValue(h.sector),
        TextCellValue(h.ayudaRecibida.isEmpty ? 'Ninguna' : h.ayudaRecibida),
        TextCellValue(h.condicionVivienda),
        TextCellValue(h.tipoVivienda),
        TextCellValue(h.tieneDiscapacidad ? 'Sí' : 'No'),
        TextCellValue(h.tieneEnfermedadCronica ? 'Sí' : 'No'),
        TextCellValue(
            '${h.fechaRegistro.day}/${h.fechaRegistro.month}/${h.fechaRegistro.year}'),
      ]);
    }

    final fileBytes = excelFile.save();
    if (fileBytes != null) {
      await FileSaver.save(
        'habitantes.xlsx',
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
    final list = _notifier!.filteredHabitants;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay habitantes para exportar')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Reporte de Habitantes',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Comuniapp',
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generado: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  •  Total: ${list.length} habitante(s)',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [
                'Nombre Completo',
                'Cédula',
                'Teléfono',
                'Zona',
                'Ayuda',
                'Discap.',
                'Fecha',
              ],
              data: list
                  .map((h) => [
                        '${h.nombres} ${h.apellidos}',
                        h.cedula,
                        h.telefono.isEmpty ? '-' : h.telefono,
                        h.sector,
                        h.ayudaRecibida.isEmpty ? 'Ninguna' : h.ayudaRecibida,
                        h.tieneDiscapacidad ? 'Sí' : 'No',
                        '${h.fechaRegistro.day}/${h.fechaRegistro.month}/${h.fechaRegistro.year}',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo700),
              cellStyle: const pw.TextStyle(fontSize: 8),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo50),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 4),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (!mounted) return;

    // Usar printing para vista previa / guardar / imprimir
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'habitantes.pdf',
    );
  }
}

// ─── Dialog de Formulario ───────────────────────────────────────────────────

class _HabitanteFormDialog extends StatefulWidget {
  final Habitante? habitante;
  final void Function(Habitante) onSave;

  const _HabitanteFormDialog({this.habitante, required this.onSave});

  @override
  State<_HabitanteFormDialog> createState() => _HabitanteFormDialogState();
}

class _HabitanteFormDialogState extends State<_HabitanteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _ptoRefCtrl;
  late final TextEditingController _detallesDiscapacidadCtrl;
  late final TextEditingController _detallesEnfermedadCtrl;

  String _zona = 'Zona A';
  String _ayuda = 'Ninguna';
  String _condVivienda = 'Propia';
  String _tipoVivienda = 'Casa';
  bool _tieneDiscapacidad = false;
  bool _tieneEnfermedad = false;

  static const _zonas = ['Zona A', 'Zona B', 'Zona C', 'Zona D'];
  static const _ayudas = ['Ninguna', 'Alimentación', 'Medicinas', 'Vivienda'];
  static const _condiciones = ['Propia', 'Alquilada', 'Prestada', 'Otra'];
  static const _tipos = ['Casa', 'Apartamento', 'Rancho', 'Habitación'];

  bool get _isEditing => widget.habitante != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habitante;
    _nombresCtrl = TextEditingController(text: h?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: h?.apellidos ?? '');
    _cedulaCtrl = TextEditingController(text: h?.cedula ?? '');
    _telefonoCtrl = TextEditingController(text: h?.telefono ?? '');
    _ptoRefCtrl = TextEditingController(text: h?.puntoReferencia ?? '');
    _detallesDiscapacidadCtrl =
        TextEditingController(text: h?.detallesDiscapacidad ?? '');
    _detallesEnfermedadCtrl =
        TextEditingController(text: h?.detallesEnfermedad ?? '');
    _zona = h?.sector ?? 'Zona A';
    _ayuda = (h?.ayudaRecibida.isEmpty ?? true) ? 'Ninguna' : h!.ayudaRecibida;
    _condVivienda = h?.condicionVivienda ?? 'Propia';
    _tipoVivienda = h?.tipoVivienda ?? 'Casa';
    _tieneDiscapacidad = h?.tieneDiscapacidad ?? false;
    _tieneEnfermedad = h?.tieneEnfermedadCronica ?? false;
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _ptoRefCtrl.dispose();
    _detallesDiscapacidadCtrl.dispose();
    _detallesEnfermedadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final newH = Habitante(
      id: widget.habitante?.id ?? const Uuid().v4(),
      cedula: _cedulaCtrl.text.trim(),
      nombres: _nombresCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      sector: _zona,
      ayudaRecibida: _ayuda == 'Ninguna' ? '' : _ayuda,
      puntoReferencia: _ptoRefCtrl.text.trim(),
      tieneDiscapacidad: _tieneDiscapacidad,
      detallesDiscapacidad: _detallesDiscapacidadCtrl.text.trim(),
      tieneEnfermedadCronica: _tieneEnfermedad,
      detallesEnfermedad: _detallesEnfermedadCtrl.text.trim(),
      condicionVivienda: _condVivienda,
      tipoVivienda: _tipoVivienda,
      registeredBy: widget.habitante?.registeredBy ?? 'admin',
      fechaRegistro: widget.habitante?.fechaRegistro ?? DateTime.now(),
    );
    widget.onSave(newH);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      alignment: isMobile ? Alignment.bottomCenter : Alignment.center,
      insetPadding: isMobile ? const EdgeInsets.only(top: 40) : const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: isMobile 
          ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
          : BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabecera ──
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: isMobile ? Radius.zero : Radius.zero,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note : Icons.person_add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Habitante' : 'Nuevo Habitante',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Formulario ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Datos Personales'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_nombresCtrl, 'Nombres', Icons.person, required: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_apellidosCtrl, 'Apellidos', Icons.person_outline, required: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_cedulaCtrl, 'Cédula', Icons.badge, required: true, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_telefonoCtrl, 'Teléfono', Icons.phone, keyboardType: TextInputType.phone)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(_ptoRefCtrl, 'Punto de Referencia', Icons.location_on),
                      const SizedBox(height: 20),

                      _sectionLabel('Clasificación'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _dropdown('Zona/Sector', _zonas, _zona, (v) => setState(() => _zona = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _dropdown('Ayuda Recibida', _ayudas, _ayuda, (v) => setState(() => _ayuda = v!))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _dropdown('Condición Vivienda', _condiciones, _condVivienda, (v) => setState(() => _condVivienda = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _dropdown('Tipo Vivienda', _tipos, _tipoVivienda, (v) => setState(() => _tipoVivienda = v!))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Condición de Salud'),
                      const SizedBox(height: 8),
                      _switchRow(
                        'Tiene Discapacidad',
                        _tieneDiscapacidad,
                        (v) => setState(() => _tieneDiscapacidad = v),
                      ),
                      if (_tieneDiscapacidad) ...[
                        const SizedBox(height: 8),
                        _field(_detallesDiscapacidadCtrl, 'Detalle de Discapacidad', Icons.info_outline),
                      ],
                      const SizedBox(height: 8),
                      _switchRow(
                        'Tiene Enfermedad Crónica',
                        _tieneEnfermedad,
                        (v) => setState(() => _tieneEnfermedad = v),
                      ),
                      if (_tieneEnfermedad) ...[
                        const SizedBox(height: 8),
                        _field(_detallesEnfermedadCtrl, 'Detalle de Enfermedad', Icons.medical_information_outlined),
                      ],
                      const SizedBox(height: 24),

                      // ── Acciones ──
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submit,
                              icon: Icon(_isEditing ? Icons.save : Icons.add),
                              label: Text(_isEditing ? 'Guardar Cambios' : 'Agregar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de construcción ──

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null
          : null,
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _switchRow(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
