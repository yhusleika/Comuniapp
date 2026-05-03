import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../bloc/habitants_bloc.dart';
import '../providers/habitants_notifier.dart';
import '../../domain/entities/habitante.dart';

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

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: BlocListener<HabitantsBloc, HabitantsState>(
        listener: (context, state) {
          if (state is HabitantsLoaded) {
            setState(() {
              _notifier = HabitantsNotifier(state.habitants);
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
                        _buildHeader(theme),
                        const SizedBox(height: 20),
                        _buildFilters(theme),
                        const SizedBox(height: 20),
                        _buildDataTable(theme),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Habitantes',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _exportData,
              icon: const Icon(Icons.download),
              label: const Text('Exportar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showHabitanteModal(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

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

  Widget _buildDataTable(ThemeData theme) {
    final ds = _notifier!.dataSource;
    ds.onEdit = (h) => _showHabitanteModal(habitante: h);
    ds.onDelete = _confirmDelete;

    return Theme(
      data: theme.copyWith(
        cardColor: Colors.white,
        dividerColor: Colors.grey[200],
      ),
      child: PaginatedDataTable(
        header: const Text('Listado de Habitantes'),
        rowsPerPage: _notifier!.filteredHabitants.length > 10
            ? 10
            : (_notifier!.filteredHabitants.isEmpty
                ? 1
                : _notifier!.filteredHabitants.length),
        availableRowsPerPage: const [10, 25, 50, 100],
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Apellido')),
          DataColumn(label: Text('Cédula')),
          DataColumn(label: Text('Zona')),
          DataColumn(label: Text('Ayuda')),
          DataColumn(label: Text('Acciones')),
        ],
        source: ds,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Exportando datos a Excel... (Placeholder)')),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Confirmar Eliminación?'),
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

  void _showHabitanteModal({Habitante? habitante}) {
    final isEditing = habitante != null;
    final nombresController =
        TextEditingController(text: habitante?.nombres ?? '');
    final apellidosController =
        TextEditingController(text: habitante?.apellidos ?? '');
    final cedulaController =
        TextEditingController(text: habitante?.cedula ?? '');
    String selectedZone = habitante?.sector ?? 'Zona A';
    String selectedAid = habitante?.ayudaRecibida ?? 'Ninguna';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Habitante' : 'Nuevo Habitante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nombresController,
                    decoration: const InputDecoration(labelText: 'Nombres')),
                const SizedBox(height: 8),
                TextField(
                    controller: apellidosController,
                    decoration: const InputDecoration(labelText: 'Apellidos')),
                const SizedBox(height: 8),
                TextField(
                    controller: cedulaController,
                    decoration: const InputDecoration(labelText: 'Cédula')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedZone,
                  decoration: const InputDecoration(labelText: 'Zona'),
                  items: ['Zona A', 'Zona B', 'Zona C', 'Zona D']
                      .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                      .toList(),
                  onChanged: (v) => selectedZone = v!,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedAid,
                  decoration:
                      const InputDecoration(labelText: 'Ayuda Recibida'),
                  items: ['Alimentación', 'Medicinas', 'Vivienda', 'Ninguna']
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => selectedAid = v!,
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
                final newHabitante = Habitante(
                  id: habitante?.id ?? const Uuid().v4(),
                  cedula: cedulaController.text,
                  nombres: nombresController.text,
                  apellidos: apellidosController.text,
                  telefono: habitante?.telefono ?? '',
                  sector: selectedZone,
                  ayudaRecibida: selectedAid,
                  puntoReferencia: habitante?.puntoReferencia ?? '',
                  tieneDiscapacidad: habitante?.tieneDiscapacidad ?? false,
                  tieneEnfermedadCronica:
                      habitante?.tieneEnfermedadCronica ?? false,
                  condicionVivienda:
                      habitante?.condicionVivienda ?? 'Desconocida',
                  tipoVivienda: habitante?.tipoVivienda ?? 'Desconocida',
                  registeredBy: habitante?.registeredBy ?? 'admin',
                  fechaRegistro: habitante?.fechaRegistro ?? DateTime.now(),
                );
                if (isEditing) {
                  context
                      .read<HabitantsBloc>()
                      .add(UpdateHabitanteEvent(newHabitante));
                } else {
                  context
                      .read<HabitantsBloc>()
                      .add(CreateHabitante(newHabitante));
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Guardar Cambios' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }
}
