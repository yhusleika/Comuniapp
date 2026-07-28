import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:excel/excel.dart' hide Border;
import '../../../../core/utils/file_saver.dart';
import '../../../../core/services/document_export_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../habitantes/presentation/bloc/habitants_bloc.dart';
import '../bloc/ayudas_bloc.dart';
import '../bloc/ayudas_event.dart';
import '../bloc/ayudas_state.dart';
import '../providers/ayudas_notifier.dart';
import '../../../habitantes/domain/entities/habitante.dart';
import '../../domain/entities/ayuda_type.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../widgets/ayuda_form_modal.dart';
import '../widgets/assign_ayuda_modal.dart';

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
                      habitantsState.habitants, ayudasState.ayudaTypes, isAuditor: isVisor);
                  _notifier!.updateData(
                      habitantsState.habitants, ayudasState.ayudaTypes, isAuditor: isVisor);

                  return ListenableBuilder(
                    listenable: _notifier!,
                    builder: (context, _) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme, canCreate),
                          const SizedBox(height: 20),
                          _buildAidTypesSection(theme, ayudasState.ayudaTypes, canEdit, canDelete),
                          const SizedBox(height: 30),
                          _buildBeneficiariesSection(theme, canEdit),
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

  Widget _buildHeader(ThemeData theme, bool canCreate) {
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
        if (canCreate)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAyudaTypeModal(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Crear ayuda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAssignAyudaModal(),
                icon: const Icon(Icons.assignment_ind, size: 20),
                label: const Text('Asignar Ayuda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50E3C2),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAidTypesSection(ThemeData theme, List<AyudaType> types, bool canEdit, bool canDelete) {
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
                child: GestureDetector(
                  onTap: () => _showAyudaTypeDetails(context, type),
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
                              if (canEdit || canDelete)
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
                                    if (canEdit)
                                      const PopupMenuItem(
                                          value: 'edit', child: Text('Editar')),
                                    if (canDelete)
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBeneficiariesSection(ThemeData theme, bool canEdit) {
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
                  if (canEdit) const DataColumn(label: Text('Editar')),
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

    await DocumentExportService.exportToPDF(
      moduleName: 'AYUDAS SOCIALES',
      reportSubtitle: 'Reporte Oficial de Beneficiarios y Asignaciones',
      reportTitle: 'REPORTE FORMAL DE BENEFICIARIOS DE AYUDAS',
      description: 'El presente documento certfica la asignación formal de programas de apoyo social y asistencia comunitaria a los habitantes registrados en la plataforma ComuniApp.',
      headers: ['Nombre Completo', 'Cédula', 'Sector', 'Ayuda Asignada', 'Fecha Registro'],
      data: list.map((b) => [
        '${b.nombres} ${b.apellidos}',
        b.cedula,
        b.sector,
        b.ayudaRecibida.isEmpty ? 'Ninguna' : b.ayudaRecibida,
        '${b.fechaRegistro.day.toString().padLeft(2, '0')}/${b.fechaRegistro.month.toString().padLeft(2, '0')}/${b.fechaRegistro.year}'
      ]).toList(),
      fileName: 'beneficiarios_ayudas.pdf',
      signatureLeft: 'Firma del Coordinador de Asistencia',
      signatureRight: 'Firma del Supervisor de Desarrollo Social',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF de beneficiarios descargado'), backgroundColor: Colors.green),
      );
    }
  }

  void _confirmDeleteAidType(String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eliminar Tipo de Ayuda'),
        content: const Text('¿Está seguro de eliminar este tipo de ayuda?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              context.read<AyudasBloc>().add(DeleteAyudaTypeEvent(id));
              Navigator.pop(dialogCtx);
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
    showDialog(
      context: context,
      builder: (dialogCtx) => AyudaFormModal(
        ayudaType: ayudaType,
        onSave: (newType) {
          if (ayudaType != null) {
            context.read<AyudasBloc>().add(UpdateAyudaTypeEvent(newType));
          } else {
            context.read<AyudasBloc>().add(CreateAyudaType(newType));
          }
          Navigator.pop(dialogCtx);
        },
      ),
    );
  }

  void _showAssignAyudaModal() {
    final habitantsState = context.read<HabitantsBloc>().state;
    final List<Habitante> allHabitants = habitantsState is HabitantsLoaded
        ? habitantsState.habitants
        : [];
    final ayudasState = context.read<AyudasBloc>().state;
    final List<AyudaType> ayudaTypes = ayudasState is AyudasLoaded
        ? ayudasState.ayudaTypes
        : [];

    if (ayudaTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe registrar al menos un tipo de ayuda primero')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AssignAyudaModal(
        allHabitants: allHabitants,
        ayudaTypes: ayudaTypes,
        onAssign: (selectedHabitantes, ayudaType, descripcion) {
          for (final habitante in selectedHabitantes) {
            final String currentAids = habitante.ayudaRecibida.trim();
            final List<String> aidsList = currentAids.isEmpty || currentAids.toLowerCase() == 'ninguna'
                ? []
                : currentAids.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            
            if (!aidsList.contains(ayudaType.nombre)) {
              aidsList.add(ayudaType.nombre);
            }
            final String finalAids = aidsList.join(', ');

            final updatedH = Habitante(
              id: habitante.id,
              cedula: habitante.cedula,
              nombres: habitante.nombres,
              apellidos: habitante.apellidos,
              telefono: habitante.telefono,
              sector: habitante.sector,
              ayudaRecibida: finalAids,
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
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ayuda "${ayudaType.nombre}" asignada a ${selectedHabitantes.length} habitante(s).'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showAyudaTypeDetails(BuildContext context, AyudaType type) {
    final habitantsState = context.read<HabitantsBloc>().state;
    final List<Habitante> beneficiaries = habitantsState is HabitantsLoaded
        ? habitantsState.habitants.where((h) {
            final aids = h.ayudaRecibida.split(',').map((e) => e.trim()).toList();
            return aids.contains(type.nombre);
          }).toList()
        : [];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF416FDF)),
            const SizedBox(width: 10),
            Expanded(child: Text(type.nombre)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                type.descripcion.isNotEmpty ? type.descripcion : 'Sin descripción disponible.',
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Text(
                'Responsable: ${type.responsable}',
                style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 24),
              Text(
                'Beneficiarios Asignados (${beneficiaries.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (beneficiaries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No hay beneficiarios asignados a este tipo de ayuda.',
                    style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic),
                  ),
                )
              else
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: beneficiaries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final b = beneficiaries[idx];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${b.nombres} ${b.apellidos}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Cédula: ${b.cedula}'),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBeneficiaryEditModal(Habitante habitante) {
    final types = _notifier!.ayudaTypes.map((t) => t.nombre).toList();
    final currentAids = habitante.ayudaRecibida
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'ninguna')
        .toList();
    
    List<String> selectedAids = List<String>.from(currentAids);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Editar Ayudas: ${habitante.nombres} ${habitante.apellidos}', style: const TextStyle(color: Colors.black87)),
            content: SizedBox(
              width: 350,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccione las ayudas asignadas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    if (types.isEmpty)
                      const Text('No hay tipos de ayudas configuradas.', style: TextStyle(color: Colors.black54))
                    else
                      ...types.map((type) {
                        final isSelected = selectedAids.contains(type);
                        return CheckboxListTile(
                          activeColor: const Color(0xFF416FDF),
                          title: Text(type, style: const TextStyle(color: Colors.black87)),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedAids.add(type);
                              } else {
                                selectedAids.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    const Divider(),
                    CheckboxListTile(
                      activeColor: Colors.red,
                      title: const Text('Ninguna (Limpiar todo)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      value: selectedAids.isEmpty,
                      onChanged: (val) {
                        if (val == true) {
                          setDialogState(() {
                            selectedAids.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF416FDF),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final String finalAids = selectedAids.isEmpty ? 'Ninguna' : selectedAids.join(', ');
                  final updatedH = Habitante(
                    id: habitante.id,
                    cedula: habitante.cedula,
                    nombres: habitante.nombres,
                    apellidos: habitante.apellidos,
                    telefono: habitante.telefono,
                    sector: habitante.sector,
                    ayudaRecibida: finalAids,
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
          );
        }
      ),
    );
  }
}
