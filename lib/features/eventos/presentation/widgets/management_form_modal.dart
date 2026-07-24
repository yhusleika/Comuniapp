import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/user_roles_helper.dart';
import '../../domain/models/management_models.dart';
import '../../../habitants/domain/entities/habitante.dart';
import '../../../habitants/presentation/widgets/search_habitante_modal.dart';
import '../../../habitants/presentation/bloc/habitants_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagementFormModal extends StatefulWidget {
  final ManagementItem? item;
  final String category; // 'Eventos', 'Proyectos', 'Jornadas'
  final List<Habitante> allHabitants;
  final Function(ManagementItem) onSave;

  const ManagementFormModal({
    super.key,
    this.item,
    required this.category,
    required this.allHabitants,
    required this.onSave,
  });

  @override
  State<ManagementFormModal> createState() => _ManagementFormModalState();
}

class _ManagementFormModalState extends State<ManagementFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final TextEditingController _descController;
  late final TextEditingController _searchController;
  
  String? _selectedResponsible;
  late String _selectedStatus;
  late double _progressValue;
  late DateTime _selectedDate;
  final List<String> _photos = [];

  List<String> _responsibles = UserRolesHelper.getOperadores();

  final List<Habitante> _selectedHabitants = [];
  List<Habitante> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _searchController = TextEditingController();
    
    _selectedDate = widget.item?.date ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    if (widget.item != null && widget.item!.responsible.isNotEmpty) {
      if (!_responsibles.contains(widget.item!.responsible)) {
        _responsibles.insert(0, widget.item!.responsible);
      }
      _selectedResponsible = widget.item!.responsible;
    } else {
      _selectedResponsible = _responsibles.isNotEmpty ? _responsibles.first : '';
    }

    _loadOperadores();

    _selectedStatus = widget.item?.status ?? 'Pendiente';
    _progressValue = widget.item?.progress ?? 0.0;
    _photos.addAll(widget.item?.photos ?? []);

    // Inicializar asistentes seleccionados si estamos editando
    if (widget.item != null && widget.item!.attendeeNames.isNotEmpty) {
      for (final name in widget.item!.attendeeNames) {
        final match = widget.allHabitants.firstWhere(
          (h) => '${h.nombres} ${h.apellidos}'.trim().toLowerCase() == name.trim().toLowerCase(),
          orElse: () => Habitante(
            id: const Uuid().v4(),
            cedula: '',
            nombres: name,
            apellidos: '',
            telefono: '',
            sector: '',
            puntoReferencia: '',
            tieneDiscapacidad: false,
            tieneEnfermedadCronica: false,
            condicionVivienda: '',
            tipoVivienda: '',
            registeredBy: '',
            fechaRegistro: DateTime.now(),
          ),
        );
        _selectedHabitants.add(match);
      }
    }
  }

  Future<void> _loadOperadores() async {
    final ops = await UserRolesHelper.fetchOperadoresAsync();
    if (!mounted) return;
    setState(() {
      _responsibles = ops;
      if (widget.item != null && widget.item!.responsible.isNotEmpty) {
        if (!_responsibles.contains(widget.item!.responsible)) {
          _responsibles.insert(0, widget.item!.responsible);
        }
        _selectedResponsible = widget.item!.responsible;
      } else if (_selectedResponsible == null || !_responsibles.contains(_selectedResponsible)) {
        _selectedResponsible = _responsibles.isNotEmpty ? _responsibles.first : '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _descController.dispose();
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
      
      // Excluir ya seleccionados
      final isAlreadySelected = _selectedHabitants.any((sh) => sh.id == h.id);
      
      return (nameMatches || cedulaMatches) && !isAlreadySelected;
    }).toList();

    setState(() {
      _searchResults = filtered;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF416FDF),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _photos.add(file.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF416FDF)),
              title: const Text('Tomar Foto con Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF416FDF)),
              title: const Text('Seleccionar de Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
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
          maxWidth: 550,
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
                  Text(
                    widget.item != null
                        ? 'Editar ${widget.category}'
                        : 'Crear Nuevo ${widget.category}',
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
                      // Nombre
                      const Text(
                        'Nombre *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ej. Feria de Salud',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // Tipo de Actividad (fijado por categoría)
                      const Text(
                        'Tipo de Actividad',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: widget.category,
                        readOnly: true,
                        style: const TextStyle(color: Colors.black54),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fecha
                      const Text(
                        'Fecha *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.black87),
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF416FDF)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Responsable
                      const Text(
                        'Responsable *',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: _selectedResponsible,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: _responsibles
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r, style: const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedResponsible = v),
                      ),
                      const SizedBox(height: 16),

                      // Estatus
                      const Text(
                        'Estatus',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: _selectedStatus,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: ['Pendiente', 'En Proceso', 'Completado']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, style: const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedStatus = v!;
                            if (_selectedStatus == 'Completado') {
                              _progressValue = 1.0;
                            } else if (_selectedStatus == 'Pendiente') {
                              _progressValue = 0.0;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Progreso (Slider)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            '${(_progressValue * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                          ),
                        ],
                      ),
                      Slider(
                        value: _progressValue,
                        activeColor: const Color(0xFF416FDF),
                        inactiveColor: Colors.grey.shade200,
                        onChanged: (v) {
                          setState(() {
                            _progressValue = v;
                            if (_progressValue == 1.0) {
                              _selectedStatus = 'Completado';
                            } else if (_progressValue == 0.0) {
                              _selectedStatus = 'Pendiente';
                            } else {
                              _selectedStatus = 'En Proceso';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Detalles sobre la actividad...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Divider(color: Colors.black12),
                      const SizedBox(height: 10),

                      // Buscador de asistentes/beneficiarios múltiple
                      const Text(
                        'Asistentes / Beneficiarios',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF416FDF)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        onTap: () async {
                          final hState = context.read<HabitantsBloc>().state;
                          final hList = hState is HabitantsLoaded ? hState.habitants : widget.allHabitants;
                          final selected = await SearchHabitanteModal.show(
                            context: context,
                            allHabitants: hList,
                            multiSelect: true,
                            alreadySelected: _selectedHabitants,
                            onRegisterNew: () {
                              context.push('/habitants');
                            },
                          );
                          if (selected != null) {
                            setState(() {
                              _selectedHabitants.clear();
                              _selectedHabitants.addAll(selected);
                            });
                          }
                        },
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Buscar asistentes...',
                          hintStyle: const TextStyle(color: Colors.black38),
                          prefixIcon: const Icon(Icons.person_search, color: Color(0xFF416FDF)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Asistentes seleccionados
                      const Text(
                        'Asistentes Seleccionados:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedHabitants.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedHabitants.map((h) {
                            return Chip(
                              backgroundColor: Colors.grey.shade100,
                              side: const BorderSide(color: Colors.black12),
                              label: Text(
                                '${h.nombres} ${h.apellidos}'.trim(),
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                              deleteIcon: const Icon(Icons.cancel, size: 18, color: Colors.redAccent),
                              onDeleted: () {
                                setState(() {
                                  _selectedHabitants.removeWhere((sh) => sh.id == h.id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Ningún asistente seleccionado aún.',
                            style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      const Divider(color: Colors.black12),
                      const SizedBox(height: 10),

                      // Evidencia Fotográfica
                      const Text(
                        'Evidencia Fotográfica',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF416FDF)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF416FDF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_a_photo, color: Color(0xFF416FDF)),
                          label: const Text(
                            'Agregar Foto',
                            style: TextStyle(color: Color(0xFF416FDF), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_photos.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              final path = _photos[index];
                              return Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: kIsWeb
                                        ? Image.network(
                                            path,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image, color: Colors.grey),
                                          )
                                        : (path.startsWith('http') || path.startsWith('assets/'))
                                            ? Image.network(
                                                path,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.broken_image, color: Colors.grey),
                                              )
                                            : Image.file(
                                                File(path),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _photos.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No se han agregado imágenes de evidencia.',
                            style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic, fontSize: 13),
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
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newItem = ManagementItem(
                          id: widget.item?.id ?? const Uuid().v4(),
                          name: _nameController.text.trim(),
                          date: _selectedDate,
                          description: _descController.text.trim(),
                          responsible: _selectedResponsible!,
                          category: widget.category,
                          progress: _progressValue,
                          status: _selectedStatus,
                          attendeeNames: _selectedHabitants.map((h) => '${h.nombres} ${h.apellidos}'.trim()).toList(),
                          photos: _photos,
                        );
                        widget.onSave(newItem);
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
