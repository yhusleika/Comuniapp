import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/user_roles_helper.dart';
import '../../domain/entities/ayuda_type.dart';

class AyudaFormModal extends StatefulWidget {
  final AyudaType? ayudaType;
  final Function(AyudaType) onSave;

  const AyudaFormModal({
    super.key,
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
  
  String? _selectedResponsable;
  List<String> _responsables = UserRolesHelper.getOperadores();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ayudaType?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.ayudaType?.descripcion ?? '');
    
    if (widget.ayudaType != null && widget.ayudaType!.responsable.isNotEmpty) {
      if (!_responsables.contains(widget.ayudaType!.responsable)) {
        _responsables.insert(0, widget.ayudaType!.responsable);
      }
      _selectedResponsable = widget.ayudaType!.responsable;
    } else {
      _selectedResponsable = _responsables.isNotEmpty ? _responsables.first : '';
    }

    _loadOperadores();
  }

  Future<void> _loadOperadores() async {
    final ops = await UserRolesHelper.fetchOperadoresAsync();
    if (!mounted) return;
    setState(() {
      _responsables = ops;
      if (widget.ayudaType != null && widget.ayudaType!.responsable.isNotEmpty) {
        if (!_responsables.contains(widget.ayudaType!.responsable)) {
          _responsables.insert(0, widget.ayudaType!.responsable);
        }
        _selectedResponsable = widget.ayudaType!.responsable;
      } else if (_selectedResponsable == null || !_responsables.contains(_selectedResponsable)) {
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
          maxHeight: isMobile ? size.height * 0.75 : size.height * 0.7,
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
                  Text(
                    widget.ayudaType != null ? 'Editar Tipo de Ayuda' : 'Configurar Nueva Ayuda',
                    style: const TextStyle(
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
                        'Descripción General',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Describa los objetivos y alcances generales de este programa de ayuda...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
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
                      if (_formKey.currentState!.validate()) {
                        final newType = AyudaType(
                          id: widget.ayudaType?.id ?? const Uuid().v4(),
                          nombre: _nombreController.text.trim(),
                          responsable: _selectedResponsable!,
                          descripcion: _descripcionController.text.trim(),
                        );
                        widget.onSave(newType);
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
