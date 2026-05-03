import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_fields_dictionary.dart';
import '../bloc/censos_bloc.dart';
import '../bloc/censos_event.dart';
import 'censo_record_form_modal.dart';

class CensoFormBuilderModal extends StatefulWidget {
  const CensoFormBuilderModal({super.key});

  @override
  State<CensoFormBuilderModal> createState() => _CensoFormBuilderModalState();
}

class _CensoFormBuilderModalState extends State<CensoFormBuilderModal> {
  final nombreController = TextEditingController();
  final zonaController = TextEditingController();
  final responsableController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  final formKey = GlobalKey<FormState>();

  final Set<String> _selectedFieldIds = {};
  final Map<String, List<CensoFieldDef>> _categorizedFields =
      CensoDictionary.getCategorizedFields();

  @override
  void initState() {
    super.initState();
    for (var f in CensoDictionary.fields) {
      if (f.isRequired) {
        _selectedFieldIds.add(f.id);
      }
    }
  }

  void _showPreview() {
    if (!formKey.currentState!.validate()) return;
    if (_selectedFieldIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un campo para el censo.')),
      );
      return;
    }

    final dummyCenso = Censo(
      id: 'preview',
      nombre: nombreController.text,
      zona: zonaController.text,
      responsable: responsableController.text,
      fecha: selectedDate,
      camposSeleccionados: _selectedFieldIds.toList(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        title: const Text('Vista Previa del Formulario', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          child: CensoRecordFormModal(
            censo: dummyCenso,
            isPreview: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar Vista Previa'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              _createCenso();
            },
            child: const Text('Confirmar y Crear Censo', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _createCenso() {
    final newCenso = Censo(
      id: const Uuid().v4(),
      nombre: nombreController.text,
      zona: zonaController.text,
      responsable: responsableController.text,
      fecha: selectedDate,
      camposSeleccionados: _selectedFieldIds.toList(),
    );
    context.read<CensosBloc>().add(CreateCenso(newCenso));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2D),
      title: const Text('Nuevo Censo - Constructor', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Row(
                children: [
                   Expanded(
                     child: TextFormField(
                       controller: nombreController,
                       style: const TextStyle(color: Colors.white),
                       decoration: const InputDecoration(
                           labelText: 'Nombre del Censo',
                           labelStyle: TextStyle(color: Colors.white70)),
                       validator: (v) => v!.isEmpty ? 'Requerido' : null,
                     ),
                   ),
                   const SizedBox(width: 10),
                   Expanded(
                     child: TextFormField(
                       controller: zonaController,
                       style: const TextStyle(color: Colors.white),
                       decoration: const InputDecoration(
                           labelText: 'Zona/Comunidad',
                           labelStyle: TextStyle(color: Colors.white70)),
                       validator: (v) => v!.isEmpty ? 'Requerido' : null,
                     ),
                   ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                       controller: responsableController,
                       style: const TextStyle(color: Colors.white),
                       decoration: const InputDecoration(
                           labelText: 'Responsable',
                           labelStyle: TextStyle(color: Colors.white70)),
                       validator: (v) => v!.isEmpty ? 'Requerido' : null,
                     ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                          style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  )
                ],
              ),
              const Divider(color: Colors.white24, height: 30),
              const Text('Seleccione los campos a incluir', 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Expanded(
                child: ListView(
                  children: _categorizedFields.entries.map((entry) {
                    return ExpansionTile(
                      initiallyExpanded: false,
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: entry.value.map((field) {
                              return SizedBox(
                                width: 250, // This ensures it stays somewhat grid-like but flows responsive
                                child: CheckboxListTile(
                                  title: Text(field.label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  value: _selectedFieldIds.contains(field.id),
                                  onChanged: field.isRequired 
                                    ? null
                                    : (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedFieldIds.add(field.id);
                                      } else {
                                        _selectedFieldIds.remove(field.id);
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: Theme.of(context).primaryColor,
                                  checkColor: Colors.white,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          onPressed: _showPreview,
          child: const Text('Previsualizar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
