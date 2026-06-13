import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../habitants/domain/entities/habitante.dart';
import '../../domain/entities/ayuda_type.dart';

class AyudaFormModal extends StatefulWidget {
  final List<Habitante> allHabitants;
  final AyudaType? ayudaType;
  final Function(AyudaType, List<Habitante>) onSave;

  const AyudaFormModal({
    super.key,
    required this.allHabitants,
    this.ayudaType,
    required this.onSave,
  });

  @override
  State<AyudaFormModal> createState() => _AyudaFormModalState();
}

class _AyudaFormModalState extends State<AyudaFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _searchController;
  
  String? _selectedResponsable;
  final List<String> _responsables = [
    'María Rodríguez',
    'Juan Pérez',
    'Ana Gómez',
    'Carlos Silva',
    'Luisa Hernández'
  ];

  final List<Habitante> _selectedHabitants = [];
  List<Habitante> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ayudaType?.nombre ?? '');
    _descripcionController = TextEditingController();
    _searchController = TextEditingController();
    _selectedResponsable = widget.ayudaType != null && _responsables.contains(widget.ayudaType!.responsable)
        ? widget.ayudaType!.responsable
        : _responsables.first;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchHabitants(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final filtered = widget.allHabitants.where((h) {
      final nameMatches = h.nombres.toLowerCase().contains(query.toLowerCase()) ||
          h.apellidos.toLowerCase().contains(query.toLowerCase());
      final cedulaMatches = h.cedula.contains(query);
      
      // Exclude already selected ones
      final isAlreadySelected = _selectedHabitants.any((sh) => sh.id == h.id);
      
      return (nameMatches || cedulaMatches) && !isAlreadySelected;
    }).toList();

    setState(() {
      _searchResults = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          maxWidth: 600,
          maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
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
                  Text(
                    widget.ayudaType != null ? 'Editar Ayuda' : 'Crear Nueva Ayuda',
                    style: const TextStyle(
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
                      // Nombre de la ayuda
                      const Text(
                        'Nombre de la Ayuda *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ej. Ayuda Alimentaria',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // Fecha de creación (auto-filled, read-only)
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

                      // Responsable de la ayuda (Dropdown)
                      const Text(
                        'Responsable de la Ayuda *',
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
                        onChanged: (val) {
                          setState(() {
                            _selectedResponsable = val;
                          });
                        },
                        validator: (v) => v == null ? 'Seleccione un responsable' : null,
                      ),
                      const SizedBox(height: 16),

                      // Descripción de la ayuda (Multiline)
                      const Text(
                        'Descripción de la Ayuda',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Describa brevemente los objetivos y alcances de la ayuda...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Apartado de Beneficiarios
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Selección de Beneficiarios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                      ),
                      const SizedBox(height: 8),
                      
                      // Buscador
                      TextFormField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Buscar por Nombre o Cédula...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF416FDF)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchHabitants('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: _searchHabitants,
                      ),
                      
                      // Resultados de búsqueda
                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final habitante = _searchResults[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  '${habitante.nombres} ${habitante.apellidos}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Cédula: ${habitante.cedula} | Sector: ${habitante.sector}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF416FDF)),
                                onTap: () {
                                  setState(() {
                                    _selectedHabitants.add(habitante);
                                    _searchController.clear();
                                    _searchResults.clear();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Chips de Beneficiarios Seleccionados
                      if (_selectedHabitants.isNotEmpty) ...[
                        const Text(
                          'Beneficiarios Seleccionados:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedHabitants.map((h) {
                            return InputChip(
                              label: Text('${h.nombres} ${h.apellidos}'),
                              labelStyle: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                              backgroundColor: const Color(0xFF416FDF).withOpacity(0.08),
                              deleteIconColor: Colors.red,
                              onDeleted: () {
                                setState(() {
                                  _selectedHabitants.removeWhere((item) => item.id == h.id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Ningún habitante seleccionado aún.',
                            style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      ],
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
                        final newType = AyudaType(
                          id: widget.ayudaType?.id ?? const Uuid().v4(),
                          nombre: _nombreController.text.trim(),
                          responsable: _selectedResponsable!,
                        );
                        widget.onSave(newType, _selectedHabitants);
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
