import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../../core/services/document_export_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../../shared/helpers/sectores_helper.dart';
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

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: BlocConsumer<HabitantsBloc, HabitantsState>(
        listener: (context, state) {
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
        builder: (context, state) {
          if (state is HabitantsLoading && _notifier == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitantsLoaded) {
            if (_notifier == null) {
              _notifier = HabitantsNotifier(state.habitants, canEdit: canEdit, canDelete: canDelete);
            } else {
              _notifier!.updateHabitants(state.habitants, canEdit: canEdit, canDelete: canDelete);
            }
          }

          if (_notifier == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListenableBuilder(
            listenable: _notifier!,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme, canCreate),
                    const SizedBox(height: 20),
                    _buildFilters(theme),
                    const SizedBox(height: 20),
                    _buildDataTable(theme, canEdit || canDelete),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool canCreate) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Text(
          'Habitantes',
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
            if (canCreate) ...[
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
                  child: () {
                    final selZone = _notifier!.selectedZone;
                    final zoneItems = ['Todas', 'Sector 1', 'Sector 2', 'Sector 3', 'Sector 4', 'Zona A', 'Zona B', 'Zona C'];
                    final effZoneItems = zoneItems.contains(selZone) ? zoneItems : [selZone, ...zoneItems];
                    return DropdownButtonFormField<String>(
                      value: selZone,
                      decoration: const InputDecoration(
                          labelText: 'Sector', border: OutlineInputBorder()),
                      items: effZoneItems
                          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                          .toList(),
                      onChanged: _notifier!.updateZone,
                    );
                  }(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: () {
                    final selAid = _notifier!.selectedAid;
                    final aidItems = ['Todas', 'Alimentación', 'Medicinas', 'Vivienda', 'Ninguna'];
                    final effAidItems = aidItems.contains(selAid) ? aidItems : [selAid, ...aidItems];
                    return DropdownButtonFormField<String>(
                      value: selAid,
                      decoration: const InputDecoration(
                          labelText: 'Ayuda Recibida',
                          border: OutlineInputBorder()),
                      items: effAidItems
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: _notifier!.updateAid,
                    );
                  }(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tabla ────────────────────────────────────────────────────────────────

  Widget _buildDataTable(ThemeData theme, bool hasActions) {
    final list = _notifier!.filteredHabitants;

    if (list.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No se encontraron habitantes',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Listado de Habitantes (${list.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(),
            SizedBox(
              height: 480,
              child: Theme(
                data: theme.copyWith(
                  cardColor: Colors.white,
                  dividerColor: Colors.grey.shade200,
                ),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 850,
                  columns: [
                    const DataColumn2(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                    const DataColumn2(label: Text('Apellido', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                    const DataColumn2(label: Text('Cédula', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
                    const DataColumn2(label: Text('Edad', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
                    const DataColumn2(label: Text('Sector', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                    const DataColumn2(label: Text('Ayuda', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                    if (hasActions)
                      const DataColumn2(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
                  ],
                  rows: list.map((h) {
                    final birthDate = h.fechaNacimiento;
                    String ageText = '-';
                    if (birthDate != null) {
                      final today = DateTime.now();
                      int age = today.year - birthDate.year;
                      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
                        age--;
                      }
                      ageText = '$age';
                    }

                    final canEdit = _notifier!.canEdit;
                    final canDelete = _notifier!.canDelete;

                    return DataRow(
                      cells: [
                        DataCell(Text(h.nombres, style: const TextStyle(color: Colors.black87))),
                        DataCell(Text(h.apellidos, style: const TextStyle(color: Colors.black87))),
                        DataCell(Text(h.cedula, style: const TextStyle(color: Colors.black87))),
                        DataCell(Text(ageText, style: const TextStyle(color: Colors.black87))),
                        DataCell(Text(h.sector, style: const TextStyle(color: Colors.black87))),
                        DataCell(Text(h.ayudaRecibida.isEmpty ? 'Ninguna' : h.ayudaRecibida, style: const TextStyle(color: Colors.black87))),
                        if (hasActions)
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canEdit)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _showHabitanteModal(habitante: h),
                                ),
                              if (canDelete)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDelete(h.id),
                                ),
                            ],
                          )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
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
    final bloc = context.read<HabitantsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                bloc.add(DeleteHabitanteEvent(id));
                Navigator.pop(dialogContext);
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
      TextCellValue('Edad'),
      TextCellValue('Teléfono'),
      TextCellValue('Sector'),
      TextCellValue('Ayuda Recibida'),
      TextCellValue('Cond. Vivienda'),
      TextCellValue('Tipo Vivienda'),
      TextCellValue('Discapacidad'),
      TextCellValue('Enf. Crónica'),
      TextCellValue('Fecha Registro'),
    ]);

    // Datos
    for (var h in list) {
      final birthDate = h.fechaNacimiento;
      String ageText = '-';
      if (birthDate != null) {
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        ageText = '$age';
      }

      sheet.appendRow([
        TextCellValue(h.nombres),
        TextCellValue(h.apellidos),
        TextCellValue(h.cedula),
        TextCellValue(ageText),
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

    final headers = [
      'Nombre Completo',
      'Cédula',
      'Edad',
      'Teléfono',
      'Sector',
      'Ayuda Recibida',
      'Discap.',
      'Enf. Crónica',
      'Fecha Registro',
    ];

    final data = list.map((h) {
      final birthDate = h.fechaNacimiento;
      String ageText = '-';
      if (birthDate != null) {
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        ageText = '$age';
      }
      return [
        '${h.nombres} ${h.apellidos}',
        h.cedula,
        ageText,
        h.telefono.isEmpty ? '-' : h.telefono,
        h.sector,
        h.ayudaRecibida.isEmpty ? 'Ninguna' : h.ayudaRecibida,
        h.tieneDiscapacidad ? 'Sí' : 'No',
        h.tieneEnfermedadCronica ? 'Sí' : 'No',
        '${h.fechaRegistro.day.toString().padLeft(2, '0')}/${h.fechaRegistro.month.toString().padLeft(2, '0')}/${h.fechaRegistro.year}',
      ];
    }).toList();

    await DocumentExportService.exportToPDF(
      moduleName: 'REGISTRO DE HABITANTES',
      reportSubtitle: 'Reporte Oficial del Padrón de Habitantes',
      reportTitle: 'REPORTE FORMAL DE HABITANTES',
      description: 'El presente documento consagra la nómina oficial de ciudadanos y familias registradas en el padrón municipal comunal de ComuniApp.',
      headers: headers,
      data: data,
      fileName: 'habitantes_reporte.pdf',
      landscape: true,
      signatureLeft: 'Firma del Registrador Comunal',
      signatureRight: 'Firma del Director de Atención al Ciudadano',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF de habitantes descargado'), backgroundColor: Colors.green),
      );
    }
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
  late final TextEditingController _birthDateCtrl;
  late final TextEditingController _detallesDiscapacidadCtrl;
  late final TextEditingController _detallesEnfermedadCtrl;

  DateTime? _selectedBirthDate;
  String _zona = 'Sector 1';
  String _ayuda = 'Ninguna';
  String _condVivienda = 'Propia';
  String _tipoVivienda = 'Casa';
  bool _tieneDiscapacidad = false;
  bool _tieneEnfermedad = false;

  List<String> _dynamicSectores = SectoresHelper.defaultSectores;
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
    _selectedBirthDate = h?.fechaNacimiento;
    _birthDateCtrl = TextEditingController(
      text: _selectedBirthDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
          : '',
    );
    _detallesDiscapacidadCtrl =
        TextEditingController(text: h?.detallesDiscapacidad ?? '');
    _detallesEnfermedadCtrl =
        TextEditingController(text: h?.detallesEnfermedad ?? '');
    _zona = h?.sector ?? 'Sector 1 - Centro';
    _ayuda = (h?.ayudaRecibida.isEmpty ?? true) ? 'Ninguna' : h!.ayudaRecibida;
    _condVivienda = h?.condicionVivienda ?? 'Propia';
    _tipoVivienda = h?.tipoVivienda ?? 'Casa';
    _tieneDiscapacidad = h?.tieneDiscapacidad ?? false;
    _tieneEnfermedad = h?.tieneEnfermedadCronica ?? false;
    _loadSectores();
  }

  Future<void> _loadSectores() async {
    final list = await SectoresHelper.getAvailableSectores();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _dynamicSectores = list;
        if (!_dynamicSectores.contains(_zona)) {
          _dynamicSectores.insert(0, _zona);
        }
      });
    }
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _ptoRefCtrl.dispose();
    _birthDateCtrl.dispose();
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
      fechaNacimiento: _selectedBirthDate,
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
                          Expanded(
                            child: _field(
                              _telefonoCtrl,
                              'Teléfono',
                              Icons.phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 11,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length != 11) {
                                  return 'Debe tener exactamente 11 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedBirthDate ?? DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedBirthDate = picked;
                              _birthDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: _field(_birthDateCtrl, 'Fecha de Nacimiento', Icons.cake, required: true),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(_ptoRefCtrl, 'Punto de Referencia', Icons.location_on),
                      const SizedBox(height: 20),

                      _sectionLabel('Clasificación'),
                      const SizedBox(height: 12),
                      _dropdown('Sector', _dynamicSectores, _zona, (v) => setState(() => _zona = v!)),
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        counterText: '',
      ),
      validator: validator ?? (required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null
          : null),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    final List<String> effectiveItems = items.contains(value) ? items : [value, ...items];
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: effectiveItems
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
