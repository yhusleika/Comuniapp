import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/user_roles_helper.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';
import '../../domain/entities/censo_fields_dictionary.dart';
import '../../../habitantes/domain/entities/habitante.dart';
import '../bloc/censos_bloc.dart';
import '../bloc/censos_event.dart';

class CensoFormBuilderModal extends StatefulWidget {
  final List<Habitante> allHabitants;

  const CensoFormBuilderModal({
    super.key,
    required this.allHabitants,
  });

  @override
  State<CensoFormBuilderModal> createState() => _CensoFormBuilderModalState();
}

class _CensoFormBuilderModalState extends State<CensoFormBuilderModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  
  String? _selectedResponsable;
  List<String> _responsables = UserRolesHelper.getOperadores();
  
  // Dynamic fields selection list
  final List<String> _selectedFields = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _descripcionController = TextEditingController();
    _selectedResponsable = _responsables.isNotEmpty ? _responsables.first : '';
    _loadOperadores();

    // Core required fields preselected and locked by default
    _selectedFields.addAll([
      'es_jefe_familia',
      'jefeFamilia',
      'cedula',
    ]);
  }

  Future<void> _loadOperadores() async {
    final ops = await UserRolesHelper.fetchOperadoresAsync();
    if (!mounted) return;
    setState(() {
      _responsables = ops;
      if (_selectedResponsable == null || !_responsables.contains(_selectedResponsable)) {
        _selectedResponsable = _responsables.isNotEmpty ? _responsables.first : '';
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _toggleField(String fieldId, bool? select) {
    if (['es_jefe_familia', 'jefeFamilia', 'cedula'].contains(fieldId)) {
      // Core fields cannot be deselected
      return;
    }
    setState(() {
      if (select == true) {
        if (!_selectedFields.contains(fieldId)) {
          _selectedFields.add(fieldId);
        }
      } else {
        _selectedFields.remove(fieldId);
      }
    });
  }

  void _toggleAllFieldsInCategory(List<CensoFieldDef> fields, bool select) {
    setState(() {
      for (final field in fields) {
        if (['es_jefe_familia', 'jefeFamilia', 'cedula'].contains(field.id)) {
          // Skip core fields
          continue;
        }
        if (select) {
          if (!_selectedFields.contains(field.id)) {
            _selectedFields.add(field.id);
          }
        } else {
          _selectedFields.remove(field.id);
        }
      }
    });
  }

  Widget _buildFieldsSelector() {
    final categorized = CensoDictionary.getCategorizedFields();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFF416FDF)),
            SizedBox(width: 8),
            Text(
              'Configuración de Campos Dinámicos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF416FDF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecciona cuáles campos del diccionario formarán parte de este censo. Los campos básicos de identificación y jefe de familia están protegidos por defecto.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        
        ...categorized.entries.map((entry) {
          final categoryName = entry.key;
          final fields = entry.value;
          
          final selectedInCat = fields.where((f) => _selectedFields.contains(f.id)).length;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                expansionTileTheme: const ExpansionTileThemeData(
                  collapsedBackgroundColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '$selectedInCat de ${fields.length} campos seleccionados',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                trailing: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
                children: [
                  // Quick actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _toggleAllFieldsInCategory(fields, true),
                        icon: const Icon(Icons.select_all, size: 16),
                        label: const Text('Seleccionar todo', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF416FDF)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _toggleAllFieldsInCategory(fields, false),
                        icon: const Icon(Icons.deselect, size: 16),
                        label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),
                  
                  // Grid/Wrap of checkboxes
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 4.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: fields.length,
                        itemBuilder: (context, index) {
                          final field = fields[index];
                          final isCore = ['es_jefe_familia', 'jefeFamilia', 'cedula'].contains(field.id);
                          final isSelected = _selectedFields.contains(field.id);
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0x0C416FDF) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF416FDF) : Colors.black12,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: CheckboxListTile(
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: const Color(0xFF416FDF),
                                title: Text(
                                  field.label,
                                  style: TextStyle(
                                    color: isCore ? Colors.black38 : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: isCore ? null : (val) => _toggleField(field.id, val),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        const Divider(color: Colors.black12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      alignment: isMobile ? Alignment.bottomCenter : Alignment.center,
      insetPadding: isMobile ? const EdgeInsets.only(top: 40) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: isMobile 
          ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
          : BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: isMobile ? size.height * 0.9 : size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF416FDF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMobile ? Radius.zero : Radius.zero,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Crear Nuevo Censo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del Censo
                      const Text(
                        'Nombre del Censo *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ej. Censo Poblacional 2026',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fecha (auto-lectura)
                      const Text(
                        'Fecha de Creación',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        readOnly: true,
                        style: const TextStyle(color: Colors.black54),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF416FDF)),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Responsable del Censo (Dropdown)
                      const Text(
                        'Responsable del Censo *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: _selectedResponsable,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _responsables
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r, style: const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedResponsable = v),
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      const Text(
                        'Descripción (Sector/Comunidad) *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ej. Sector Central, Calle Bolívar',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'La descripción es obligatoria' : null,
                      ),
                      const SizedBox(height: 16),

                      const Divider(color: Colors.black12),
                      
                      // DYNAMIC FIELDS SELECTOR ACCORDIONS
                      _buildFieldsSelector(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Buttons Footer
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF416FDF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final censoId = const Uuid().v4();
                        
                        // Create Censo with dynamically selected fields
                        final newCenso = Censo(
                          id: censoId,
                          nombre: _nombreController.text.trim(),
                          zona: _descripcionController.text.trim(),
                          responsable: _selectedResponsable!,
                          fecha: DateTime.now(),
                          camposSeleccionados: List<String>.from(_selectedFields),
                        );

                        // Dispatch Censo creation
                        context.read<CensosBloc>().add(CreateCenso(newCenso));

                        // Close modal
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
