import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../bloc/censos_bloc.dart';
import '../bloc/censos_event.dart';
import '../bloc/censos_state.dart';
import '../providers/censos_notifier.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';
import '../widgets/censo_form_builder_modal.dart';
import '../widgets/censo_record_form_modal.dart';

class CensosPage extends StatelessWidget {
  const CensosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CensosBloc>()..add(LoadCensos())),
      ],
      child: ChangeNotifierProvider(
        create: (_) => CensosNotifier(),
        child: const CensosView(),
      ),
    );
  }
}

class CensosView extends StatefulWidget {
  const CensosView({super.key});

  @override
  State<CensosView> createState() => _CensosViewState();
}

class _CensosViewState extends State<CensosView> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  CensosNotifier? _notifier;

  @override
  Widget build(BuildContext context) {
    _notifier = Provider.of<CensosNotifier>(context);

    return CustomScaffold(
      scaffoldKey: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: BlocListener<CensosBloc, CensosState>(
        listener: (context, state) {
          if (state is CensosLoaded) {
            final oldLen = _notifier!.censos.length;
            _notifier!.updateCensos(state.censos);
            if (state.censos.length > oldLen) {
              _notifier!.selectCenso(state.censos.last);
            }
            if (_notifier!.selectedCenso != null) {
              context
                  .read<CensosBloc>()
                  .add(LoadCensoRecords(_notifier!.selectedCenso!.id));
            }
          } else if (state is CensoRecordsLoaded) {
            _notifier!.updateRecords(state.records);
          } else if (state is CensoOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Operación exitosa'),
                  backgroundColor: Colors.green),
            );
          } else if (state is CensoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildFilters(context),
              const SizedBox(height: 20),
              if (_notifier!.selectedCenso != null)
                _buildTable(context)
              else
                const Center(
                    child: Text('Cree un censo para comenzar',
                        style: TextStyle(color: Colors.white70, fontSize: 18))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Gestión de Censos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            if (_notifier!.censos.isNotEmpty)
              DropdownButton<Censo>(
                dropdownColor: const Color(0xFF1E1E2D),
                value: _notifier!.selectedCenso,
                items: _notifier!.censos.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.nombre,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (c) {
                  _notifier!.selectCenso(c);
                  context.read<CensosBloc>().add(LoadCensoRecords(c!.id));
                },
              ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showCensoModal(),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Censo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => _notifier!.setSearchQuery(v),
                  decoration: InputDecoration(
                    hintText: 'Buscar jefe de familia o cédula...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1E1E2D),
                  value: _notifier!.statusFilter,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Estatus',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['Todos', 'Censados', 'Pendientes', 'Casos Especiales']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => _notifier!.setStatusFilter(v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Text(
                'Resultados: ${_notifier!.filteredRecords.length}',
                style: const TextStyle(color: Colors.white70),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Función de exportación en desarrollo')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Exportar Censo a Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                const Text(
                  'Registros de Familia',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () => _showRecordModal(),
                  child: const Text('Agregar Registro'),
                ),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.white,
              textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.black87,
                    displayColor: Colors.black87,
                  ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            child: PaginatedDataTable(
              header: null,
              rowsPerPage: 10,
              showFirstLastButtons: true,
              columns: const [
                DataColumn(label: Text('Jefe de Familia')),
                DataColumn(label: Text('Cédula')),
                DataColumn(label: Text('Dirección')),
                DataColumn(label: Text('Hijos')),
                DataColumn(label: Text('Estatus')),
                DataColumn(label: Text('Acciones')),
              ],
              source: FamilyRecordsDataTableSource(
                records: _notifier!.filteredRecords,
                context: context,
                onEdit: (r) => _showRecordModal(record: r),
                onDelete: (r) => _confirmDelete(r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCensoModal() {
    final bloc = context.read<CensosBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const CensoFormBuilderModal(),
      ),
    );
  }

  void _showRecordModal({CensoRecord? record}) {
    final bloc = context.read<CensosBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CensoRecordFormModal(
          censo: _notifier!.selectedCenso!,
          record: record,
        ),
      ),
    );
  }

  void _confirmDelete(CensoRecord record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        title: const Text('Eliminar Registro',
            style: TextStyle(color: Colors.white)),
        content: Text(
            '¿Está seguro de eliminar el registro de ${record.jefeFamilia}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CensosBloc>().add(DeleteCensoRecordEvent(record.id));
              // Also reload manually since delete event doesn't have censoId
              context.read<CensosBloc>().add(LoadCensoRecords(record.censoId));
              Navigator.pop(context);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
