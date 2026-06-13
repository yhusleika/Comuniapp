import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/file_saver.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../habitants/presentation/bloc/habitants_bloc.dart';
import '../bloc/ayudas_bloc.dart';
import '../bloc/ayudas_event.dart';
import '../bloc/ayudas_state.dart';
import '../providers/ayudas_notifier.dart';
import '../../../habitants/domain/entities/habitante.dart';
import '../../domain/entities/ayuda_type.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../widgets/ayuda_form_modal.dart';

class AyudasPage extends StatelessWidget {
  const AyudasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AyudasBloc>()..add(LoadAyudaTypes())),
        BlocProvider(
            create: (_) => sl<HabitantsBloc>()..add(const LoadHabitants())),
      ],
      child: const AyudasView(),
    );
  }
}

class AyudasView extends StatefulWidget {
  const AyudasView({super.key});

  @override
  State<AyudasView> createState() => _AyudasViewState();
}

class _AyudasViewState extends State<AyudasView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  AyudasNotifier? _notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isAuditor = authState is AuthAuthenticated && authState.user.role.toLowerCase() == 'auditor';

    return CustomScaffold(
      scaffoldKey: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AyudasBloc, AyudasState>(
            listener: (context, state) {
              if (state is AyudaOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Operación exitosa'),
                      backgroundColor: Colors.green),
                );
              }
              if (state is AyudasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: ${state.message}'),
                      backgroundColor: Colors.red),
                );
              }
              _updateNotifier();
            },
          ),
          BlocListener<HabitantsBloc, HabitantsState>(
            listener: (context, state) {
              if (state is HabitanteOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Beneficiario actualizado'),
                      backgroundColor: Colors.green),
                );
              }
              _updateNotifier();
            },
          ),
        ],
        child: BlocBuilder<AyudasBloc, AyudasState>(
          builder: (context, ayudasState) {
            return BlocBuilder<HabitantsBloc, HabitantsState>(
              builder: (context, habitantsState) {
                if (ayudasState is AyudasLoading ||
                    habitantsState is HabitantsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (ayudasState is AyudasLoaded &&
                    habitantsState is HabitantsLoaded) {
                  _notifier ??= AyudasNotifier(
                      habitantsState.habitants, ayudasState.ayudaTypes, isAuditor: isAuditor);
                  _notifier!.updateData(
                      habitantsState.habitants, ayudasState.ayudaTypes);

                  return ListenableBuilder(
                    listenable: _notifier!,
                    builder: (context, _) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme, isAuditor),
                          const SizedBox(height: 20),
                          _buildAidTypesSection(theme, ayudasState.ayudaTypes, isAuditor),
                          const SizedBox(height: 30),
                          _buildBeneficiariesSection(theme, isAuditor),
                        ],
                      ),
                    ),
                  );
                }

                return const Center(
                    child: Text('Error al cargar datos',
                        style: TextStyle(color: Colors.white)));
              },
            );
          },
        ),
      ),
    );
  }

  void _updateNotifier() {
    final ayudasState = context.read<AyudasBloc>().state;
    final habitantsState = context.read<HabitantsBloc>().state;
    if (ayudasState is AyudasLoaded && habitantsState is HabitantsLoaded) {
      _notifier?.updateData(habitantsState.habitants, ayudasState.ayudaTypes);
    }
  }

  Widget _buildHeader(ThemeData theme, bool isAuditor) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Text(
          'Gestión de Ayudas',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        if (!isAuditor)
          IconButton(
            onPressed: () => _showAyudaTypeModal(),
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
      ],
    );
  }

  Widget _buildAidTypesSection(ThemeData theme, List<AyudaType> types, bool isAuditor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipos de Ayudas Disponibles',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(type.nombre,
                                    style: const TextStyle(
                                         fontWeight: FontWeight.bold,
                                         fontSize: 16))),
                            if (!isAuditor)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showAyudaTypeModal(ayudaType: type);
                                  }
                                  if (value == 'delete') {
                                    _confirmDeleteAidType(type.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Editar')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Eliminar')),
                                ],
                                icon: const Icon(Icons.more_vert, size: 20),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text('Resp: ${type.responsable}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
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

  Widget _buildBeneficiariesSection(ThemeData theme, bool isAuditor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Beneficiarios Activos',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: Colors.white70)),
            Row(
              children: [
                IconButton(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_view, color: Colors.white),
                  tooltip: 'Exportar a Excel',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.all(10),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  tooltip: 'Exportar a PDF',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.all(10),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _notifier!.updateSearch,
              decoration: InputDecoration(
                hintText: 'Buscar beneficiario...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Theme(
          data: theme.copyWith(cardColor: Colors.white),
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
                header: const Text('Listado de Beneficiarios'),
                rowsPerPage: _notifier!.filteredBeneficiaries.length > 10
                    ? 10
                    : (_notifier!.filteredBeneficiaries.isEmpty
                        ? 1
                        : _notifier!.filteredBeneficiaries.length),
                columns: [
                  const DataColumn(label: Text('Nombre')),
                  const DataColumn(label: Text('Cédula')),
                  const DataColumn(label: Text('Ayuda')),
                  const DataColumn(label: Text('Fecha')),
                  if (!isAuditor) const DataColumn(label: Text('Editar')),
                ],
                source: _notifier!.dataSource..onEdit = _showBeneficiaryEditModal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel() async {
    final list = _notifier!.filteredBeneficiaries;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay beneficiarios activos para exportar')),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Header
    sheetObject.appendRow([
      TextCellValue('Nombre'),
      TextCellValue('Apellido'),
      TextCellValue('Cédula'),
      TextCellValue('Ayuda Asignada'),
      TextCellValue('Fecha')
    ]);

    // Data
    for (var b in list) {
      sheetObject.appendRow([
        TextCellValue(b.nombres),
        TextCellValue(b.apellidos),
        TextCellValue(b.cedula),
        TextCellValue(b.ayudaRecibida),
        TextCellValue('${b.fechaRegistro.day}/${b.fechaRegistro.month}/${b.fechaRegistro.year}')
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.save(
        'beneficiarios_ayudas.xlsx',
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
    final list = _notifier!.filteredBeneficiaries;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay beneficiarios activos para exportar')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Reporte de Beneficiarios de Ayudas', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Nombre', 'Cédula', 'Ayuda Asignada', 'Fecha'],
              data: list.map((b) => [
                '${b.nombres} ${b.apellidos}',
                b.cedula,
                b.ayudaRecibida,
                '${b.fechaRegistro.day}/${b.fechaRegistro.month}/${b.fechaRegistro.year}'
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await FileSaver.save(
      'beneficiarios_ayudas.pdf',
      bytes,
      'application/pdf',
      (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
          );
        }
      },
    );
  }

  void _confirmDeleteAidType(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tipo de Ayuda'),
        content: const Text('¿Está seguro de eliminar este tipo de ayuda?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              context.read<AyudasBloc>().add(DeleteAyudaTypeEvent(id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAyudaTypeModal({AyudaType? ayudaType}) {
    final habitantsState = context.read<HabitantsBloc>().state;
    final List<Habitante> allHabitants = habitantsState is HabitantsLoaded
        ? habitantsState.habitants
        : [];

    showDialog(
      context: context,
      builder: (dialogCtx) => AyudaFormModal(
        allHabitants: allHabitants,
        ayudaType: ayudaType,
        onSave: (newType, selectedHabitants) {
          if (ayudaType != null) {
            context.read<AyudasBloc>().add(UpdateAyudaTypeEvent(newType));
          } else {
            context.read<AyudasBloc>().add(CreateAyudaType(newType));
          }

          for (var h in selectedHabitants) {
            final updatedH = Habitante(
              id: h.id,
              cedula: h.cedula,
              nombres: h.nombres,
              apellidos: h.apellidos,
              telefono: h.telefono,
              sector: h.sector,
              ayudaRecibida: newType.nombre,
              puntoReferencia: h.puntoReferencia,
              tieneDiscapacidad: h.tieneDiscapacidad,
              tieneEnfermedadCronica: h.tieneEnfermedadCronica,
              condicionVivienda: h.condicionVivienda,
              tipoVivienda: h.tipoVivienda,
              registeredBy: h.registeredBy,
              fechaRegistro: h.fechaRegistro,
              detallesDiscapacidad: h.detallesDiscapacidad,
              detallesEnfermedad: h.detallesEnfermedad,
            );
            context.read<HabitantsBloc>().add(UpdateHabitanteEvent(updatedH));
          }

          Navigator.pop(dialogCtx);
        },
      ),
    );
  }

  void _showBeneficiaryEditModal(Habitante habitante) {
    String selectedAid = habitante.ayudaRecibida;
    final types = _notifier!.ayudaTypes.map((t) => t.nombre).toList();
    if (!types.contains('Ninguna')) types.add('Ninguna');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Ayuda: ${habitante.nombres}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cambie el tipo de ayuda asignada:'),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: types.contains(selectedAid) ? selectedAid : types.first,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => selectedAid = v!,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Ayuda'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final updatedH = Habitante(
                id: habitante.id,
                cedula: habitante.cedula,
                nombres: habitante.nombres,
                apellidos: habitante.apellidos,
                telefono: habitante.telefono,
                sector: habitante.sector,
                ayudaRecibida: selectedAid,
                puntoReferencia: habitante.puntoReferencia,
                tieneDiscapacidad: habitante.tieneDiscapacidad,
                tieneEnfermedadCronica: habitante.tieneEnfermedadCronica,
                condicionVivienda: habitante.condicionVivienda,
                tipoVivienda: habitante.tipoVivienda,
                registeredBy: habitante.registeredBy,
                fechaRegistro: habitante.fechaRegistro,
                detallesDiscapacidad: habitante.detallesDiscapacidad,
                detallesEnfermedad: habitante.detallesEnfermedad,
              );
              context.read<HabitantsBloc>().add(UpdateHabitanteEvent(updatedH));
              Navigator.pop(context);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
