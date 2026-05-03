import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
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

    return CustomScaffold(
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
                      habitantsState.habitants, ayudasState.ayudaTypes);
                  _notifier!.updateData(
                      habitantsState.habitants, ayudasState.ayudaTypes);

                  return ListenableBuilder(
                    listenable: _notifier!,
                    builder: (context, _) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme),
                          const SizedBox(height: 20),
                          _buildAidTypesSection(theme, ayudasState.ayudaTypes),
                          const SizedBox(height: 30),
                          _buildBeneficiariesSection(theme),
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

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Gestión de Ayudas',
          style: theme.textTheme.headlineMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAyudaTypeModal(),
          icon: const Icon(Icons.add),
          label: const Text('Crear Nueva Ayuda'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAidTypesSection(ThemeData theme, List<AyudaType> types) {
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
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit')
                                  _showAyudaTypeModal(ayudaType: type);
                                if (value == 'delete')
                                  _confirmDeleteAidType(type.id);
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

  Widget _buildBeneficiariesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Beneficiarios Activos',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: Colors.white70)),
            ElevatedButton.icon(
              onPressed: _exportBeneficiaries,
              icon: const Icon(Icons.download),
              label: const Text('Exportar a Excel'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
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
          child: PaginatedDataTable(
            header: const Text('Listado de Beneficiarios'),
            rowsPerPage: _notifier!.filteredBeneficiaries.length > 10
                ? 10
                : (_notifier!.filteredBeneficiaries.isEmpty
                    ? 1
                    : _notifier!.filteredBeneficiaries.length),
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Cédula')),
              DataColumn(label: Text('Ayuda')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Editar')),
            ],
            source: _notifier!.dataSource..onEdit = _showBeneficiaryEditModal,
          ),
        ),
      ],
    );
  }

  void _exportBeneficiaries() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Exportando beneficiarios visibles... (Placeholder)')),
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
    final isEditing = ayudaType != null;
    final nombreController =
        TextEditingController(text: ayudaType?.nombre ?? '');
    final responsableController =
        TextEditingController(text: ayudaType?.responsable ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Editar Ayuda' : 'Nueva Ayuda'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration:
                    const InputDecoration(labelText: 'Nombre de la Ayuda'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: responsableController,
                decoration: const InputDecoration(labelText: 'Responsable'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newType = AyudaType(
                  id: ayudaType?.id ?? const Uuid().v4(),
                  nombre: nombreController.text,
                  responsable: responsableController.text,
                );
                if (isEditing) {
                  context.read<AyudasBloc>().add(UpdateAyudaTypeEvent(newType));
                } else {
                  context.read<AyudasBloc>().add(CreateAyudaType(newType));
                }
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Crear'),
          ),
        ],
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
