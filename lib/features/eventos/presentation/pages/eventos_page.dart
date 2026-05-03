import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../domain/models/management_models.dart';
import 'package:go_router/go_router.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  // State
  String _selectedCategory = 'Eventos';
  String _searchQuery = '';
  bool _isCreating = false;
  String? _expandedItemId;
  bool _hasUnsavedChanges = false;

  // Controllers
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _descController = TextEditingController();
  final _respController = TextEditingController();

  // Mock Data
  late List<ManagementItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      ManagementItem(
          id: '1',
          name: 'Mantenimiento Parque',
          date: DateTime.now(),
          description: 'Limpieza y pintura',
          responsible: 'Juan Pérez',
          category: 'Proyectos',
          progress: 0.4,
          status: 'En Proceso'),
      ManagementItem(
          id: '2',
          name: 'Vacunación Infantil',
          date: DateTime.now(),
          description: 'Jornada médica',
          responsible: 'Ana López',
          category: 'Jornadas',
          progress: 0.1,
          status: 'Pendiente'),
      ManagementItem(
          id: '3',
          name: 'Feria Comunitaria',
          date: DateTime.now(),
          description: 'Evento cultural',
          responsible: 'Carlos Ruiz',
          category: 'Eventos',
          progress: 0.8,
          status: 'En Proceso'),
    ];
  }

  List<ManagementItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = item.category == _selectedCategory;
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _resetForm() {
    _nameController.clear();
    _dateController.clear();
    _descController.clear();
    _respController.clear();
  }

  void _saveNewItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _items.add(ManagementItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          date: DateTime.parse(_dateController.text),
          description: _descController.text,
          responsible: _respController.text,
          category: _selectedCategory,
        ));
        _isCreating = false;
        _resetForm();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedCategory guardado con éxito')),
      );
    }
  }

  void _saveStatusChanges() {
    setState(() {
      _hasUnsavedChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios de estatus guardados correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      floatingActionButton: _hasUnsavedChanges
          ? FloatingActionButton.extended(
              onPressed: _saveStatusChanges,
              backgroundColor: theme.colorScheme.secondary,
              label: const Text('Actualizar Estatus',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.save),
            )
          : null,
      child: Column(
        children: [
          // Navigation Superior (Buttons)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Eventos', 'Proyectos', 'Jornadas'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return ElevatedButton(
                  onPressed: () => setState(() {
                    _selectedCategory = cat;
                    _isCreating = false;
                    _expandedItemId = null;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    foregroundColor: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  child: Text(cat),
                );
              }).toList(),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mode Resolver
          Expanded(
            child:
                _isCreating ? _buildCreateForm(theme) : _buildListView(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isCreating = true),
              icon: const Icon(Icons.add),
              label: Text('Crear Nuevo $_selectedCategory'),
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              final isExpanded = _expandedItemId == item.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Expanded(
                              child: Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: Colors.grey[300],
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(item.progress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      subtitle: Text(
                          'Resp: ${item.responsible} • ${item.date.toString().substring(0, 10)}'),
                      trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more),
                      onTap: () => setState(
                          () => _expandedItemId = isExpanded ? null : item.id),
                    ),
                    if (isExpanded) _buildExpandedForm(item, theme),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuevo $_selectedCategory',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 20),
                _buildField('Nombre', _nameController),
                _buildField('Fecha (YYYY-MM-DD)', _dateController,
                    hint: '2024-02-15'),
                _buildField('Responsable', _respController),
                _buildField('Descripción', _descController, maxLines: 3),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isCreating = false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveNewItem,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedForm(ManagementItem item, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Estatus:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: item.status,
                items: ['Pendiente', 'En Proceso', 'Completado'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != item.status) {
                    setState(() {
                      final idx = _items.indexWhere((i) => i.id == item.id);
                      _items[idx] = item.copyWith(status: val);
                      _hasUnsavedChanges = true;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(
              'Descripción:', TextEditingController(text: item.description),
              enabled: false, maxLines: 2),
          const SizedBox(height: 16),
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to details and show Snackbar
                    context.push('/eventos/details', extra: item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Accediendo a la tabla para incluir datos...')),
                    );
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Incluir Datos'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {String? hint, int maxLines = 1, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
        ),
        validator: (val) =>
            val == null || val.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }
}
