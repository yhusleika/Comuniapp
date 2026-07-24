import 'package:flutter/material.dart';
import '../../../habitants/domain/entities/habitante.dart';
import '../../../habitants/presentation/widgets/search_habitante_modal.dart';
import '../../domain/entities/ayuda_type.dart';

class AssignAyudaModal extends StatefulWidget {
  final List<Habitante> allHabitants;
  final List<AyudaType> ayudaTypes;
  final Function(List<Habitante>, AyudaType, String) onAssign;

  const AssignAyudaModal({
    super.key,
    required this.allHabitants,
    required this.ayudaTypes,
    required this.onAssign,
  });

  @override
  State<AssignAyudaModal> createState() => _AssignAyudaModalState();
}

class _AssignAyudaModalState extends State<AssignAyudaModal> {
  final _formKey = GlobalKey<FormState>();
  List<Habitante> _selectedHabitantes = [];
  AyudaType? _selectedAyudaType;
  final _descripcionController = TextEditingController();

  void _openSearchHabitante() async {
    final selectedList = await SearchHabitanteModal.show(
      context: context,
      allHabitants: widget.allHabitants,
      multiSelect: true,
    );

    if (selectedList != null && selectedList.isNotEmpty) {
      setState(() {
        _selectedHabitantes = selectedList;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.ayudaTypes.isNotEmpty) {
      _selectedAyudaType = widget.ayudaTypes.first;
    }
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
          maxWidth: 500,
          maxHeight: isMobile ? size.height * 0.75 : size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF416FDF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Asignar Ayuda Social (Múltiple)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                      // Habitantes Selection (Múltiple)
                      const Text(
                        'Seleccionar Beneficiarios (Múltiple) *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_selectedHabitantes.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x0D416FDF),
                            border: Border.all(color: const Color(0xFF416FDF), width: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedHabitantes.length} habitante(s) seleccionado(s)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                                  ),
                                  TextButton.icon(
                                    onPressed: _openSearchHabitante,
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Modificar'),
                                  ),
                                ],
                              ),
                              const Divider(height: 8),
                              ..._selectedHabitantes.map((h) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('• ${h.nombres} ${h.apellidos} (${h.cedula})', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              )),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: _openSearchHabitante,
                            icon: const Icon(Icons.person_search, color: Color(0xFF416FDF)),
                            label: const Text(
                              'Buscar y Seleccionar Habitantes...',
                              style: TextStyle(color: Color(0xFF416FDF), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF416FDF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),

                      // AyudaType Dropdown
                      const Text(
                        'Tipo de Ayuda *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AyudaType>(
                        dropdownColor: Colors.white,
                        value: _selectedAyudaType,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: widget.ayudaTypes
                            .map((t) => DropdownMenuItem<AyudaType>(
                                  value: t,
                                  child: Text(t.nombre, style: const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAyudaType = val;
                          });
                        },
                        validator: (v) => v == null ? 'Seleccione el tipo de ayuda' : null,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Descripción de la Entrega *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ej: Entrega de tratamiento para 30 días',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Describa la entrega' : null,
                      ),
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
                    ),
                    onPressed: () {
                      if (_selectedHabitantes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debe seleccionar al menos un habitante'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }
                      if (_formKey.currentState!.validate() && _selectedAyudaType != null) {
                        widget.onAssign(_selectedHabitantes, _selectedAyudaType!, _descripcionController.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Asignar a Selección', style: TextStyle(fontWeight: FontWeight.bold)),
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
