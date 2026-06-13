import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';
import '../../domain/entities/censo_fields_dictionary.dart';
import '../bloc/censos_bloc.dart';
import '../bloc/censos_event.dart';

class CensoRecordFormModal extends StatefulWidget {
  final Censo censo;
  final CensoRecord? record;
  final bool isPreview;

  const CensoRecordFormModal({
    super.key,
    required this.censo,
    this.record,
    this.isPreview = false,
  });

  @override
  State<CensoRecordFormModal> createState() => _CensoRecordFormModalState();
}

class _CensoRecordFormModalState extends State<CensoRecordFormModal> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final List<Map<String, dynamic>> _familyMembers = [];

  late List<CensoFieldDef> _activeFields;
  late List<CensoFieldDef> _personasFields;

  @override
  void initState() {
    super.initState();
    _activeFields = CensoDictionary.fields
        .where((f) => widget.censo.camposSeleccionados.contains(f.id))
        .toList();
        
    _personasFields = _activeFields.where((f) => f.category == 'Datos de Personas').toList();

    if (widget.record != null) {
      _formData.addAll(widget.record!.datosDinamicos);
      if (widget.record!.datosDinamicos.containsKey('familiares') && 
          widget.record!.datosDinamicos['familiares'] is List) {
        _familyMembers.addAll(
            List<Map<String, dynamic>>.from(widget.record!.datosDinamicos['familiares']));
      }
    } else {
      _formData['estatus'] = 'Censados';
      // Auto-add at least one member if personas fields are available
      if (_personasFields.isNotEmpty) {
        _familyMembers.add({'es_jefe_familia': 'Sí'});
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    if (_personasFields.isNotEmpty) {
      _formData['familiares'] = _familyMembers;
    }

    if (widget.isPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operación exitosa (Modo Vista Previa)')),
      );
      return;
    }

    // Determine Jefe de familia
    String jefeNombre = 'Sin Nombre';
    String jefeCedula = '';
    
    try {
      final jefe = _familyMembers.firstWhere((p) => p['es_jefe_familia'] == 'Sí', orElse: () => _familyMembers.isNotEmpty ? _familyMembers.first : {});
      jefeNombre = jefe['jefeFamilia']?.toString() ?? 'Sin Nombre';
      jefeCedula = jefe['cedula']?.toString() ?? '';
    } catch (_) {}

    final newRecord = CensoRecord(
      id: widget.record?.id ?? const Uuid().v4(),
      censoId: widget.censo.id,
      jefeFamilia: jefeNombre,
      cedula: jefeCedula,
      direccion: _formData['no_casa_existente']?.toString() ?? 
                 _formData['sector']?.toString() ?? '',
      numeroHijos: _familyMembers.where((f) => f['parentesco']?.toString().toLowerCase().contains('hijo') == true).length,
      estatus: _formData['estatus']?.toString() ?? 'Censados',
      datosDinamicos: Map<String, dynamic>.from(_formData),
    );

    if (widget.record != null) {
      context.read<CensosBloc>().add(UpdateCensoRecordEvent(newRecord));
    } else {
      context.read<CensosBloc>().add(AddCensoRecordEvent(newRecord));
    }

    Navigator.pop(context);
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Widget _buildFieldGridRow(List<CensoFieldDef> fields, Map<String, dynamic> dataMap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: fields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildDynamicWidget(field, dataMap),
              );
            }).toList(),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields.map((field) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: _buildDynamicWidget(field, dataMap),
                  ),
                );
              }).toList()
              ..addAll(List.generate(
                (2 - fields.length).clamp(0, 2), 
                (_) => const Expanded(child: SizedBox()),
              )),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<CensoFieldDef>> categoryWidgetsData = {};
    List<String> orderedCategories = [];
    
    for (var field in _activeFields) {
      if (!orderedCategories.contains(field.category)) {
        orderedCategories.add(field.category);
      }
      if (field.category == 'Datos de Personas') continue; 
      
      if (!categoryWidgetsData.containsKey(field.category)) {
        categoryWidgetsData[field.category] = [];
      }
      categoryWidgetsData[field.category]!.add(field);
    }

    Widget content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...orderedCategories.map((category) {
            if (category == 'Datos de Personas' && _personasFields.isNotEmpty) {
               return _buildFamilyCompositionCard();
            }
            
            final fields = categoryWidgetsData[category] ?? [];
            if (fields.isEmpty) return const SizedBox.shrink();
            
            final fieldChunks = _chunkList(fields, 2);
            return Card(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12),
              ),
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 10),
                    ...fieldChunks.map((chunk) => _buildFieldGridRow(chunk, _formData)),
                  ],
                ),
              ),
            );
          }),
            
           Card(
             color: Colors.white,
             surfaceTintColor: Colors.transparent,
             elevation: 2,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(12),
               side: const BorderSide(color: Colors.black12),
             ),
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    value: _formData['estatus'] ?? 'Censados',
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                        labelText: 'Estatus del Censo',
                        labelStyle: TextStyle(color: Colors.black54)),
                    items: ['Censados', 'Pendientes', 'Casos Especiales']
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(color: Colors.black87))))
                        .toList(),
                    onChanged: (v) => setState(() => _formData['estatus'] = v),
                  ),
              )
           )
        ],
      )
    );

    if (widget.isPreview) return content;

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
          maxWidth: 750,
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
                    widget.record != null ? 'Editar Registro' : 'Agregar Registro',
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
            // Form body wrapped in Expanded/Flexible
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: content,
                ),
              ),
            ),
            // Footer
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
                    onPressed: _save,
                    child: Text(widget.record != null ? 'Guardar' : 'Agregar', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCompositionCard() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                const Text('Datos de Personas', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _familyMembers.add({'es_jefe_familia': 'No'});
                    });
                  },
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Agregar Integrante'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                  ),
                )
              ],
            ),
            const Divider(color: Colors.black12),
            if (_familyMembers.isEmpty)
               const Text('Sin integrantes. Presione "Agregar Integrante".', style: TextStyle(color: Colors.black54)),
            ..._familyMembers.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> member = entry.value;

              final fieldChunks = _chunkList(_personasFields, 2);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Integrante #${index + 1}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _familyMembers.removeAt(index);
                            });
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...fieldChunks.map((chunk) => _buildFieldGridRow(chunk, member)),
                  ],
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicWidget(CensoFieldDef field, Map<String, dynamic> dataMap) {
    // Helper to check if "Otros" needs a mention text block
    bool showOtrosField = false;
    final value = dataMap[field.id];
    
    if (value != null) {
      if (value is String && value.toLowerCase().contains('otro')) {
        showOtrosField = true;
      } else if (value is List && value.any((e) => e.toString().toLowerCase().contains('otro'))) {
        showOtrosField = true;
      }
    }

    Widget mainWidget;

    switch (field.type) {
      case FieldType.text:
      case FieldType.number:
        mainWidget = TextFormField(
          initialValue: dataMap[field.id]?.toString() ?? '',
          style: const TextStyle(color: Colors.black87),
          keyboardType: field.type == FieldType.number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              labelText: field.label + (field.isRequired ? ' *' : ''),
              labelStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.grey.shade50),
          validator: field.isRequired ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null : null,
          onChanged: (v) => setState(() => dataMap[field.id] = v),
          onSaved: (v) => dataMap[field.id] = v,
        );
        break;
      case FieldType.dropdown:
        mainWidget = DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          value: dataMap[field.id],
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
              isDense: true,
              labelText: field.label + (field.isRequired ? ' *' : ''),
              labelStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.grey.shade50),
          items: (field.options ?? [])
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87))))
              .toList(),
          onChanged: (v) => setState(() => dataMap[field.id] = v),
          onSaved: (v) => dataMap[field.id] = v,
          validator: field.isRequired ? (v) => v == null ? 'Requerido' : null : null,
        );
        break;
      case FieldType.checkboxList:
      case FieldType.radio:
        List<String> currentSelected = [];
        if (dataMap[field.id] != null && dataMap[field.id] is List) {
           currentSelected = List<String>.from(dataMap[field.id]);
        } else if (dataMap[field.id] != null && dataMap[field.id] is String) {
           currentSelected = [dataMap[field.id]];
        }
        mainWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label + (field.isRequired ? ' *' : ''), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8.0,
              children: (field.options ?? []).map((option) {
                final isSelected = currentSelected.contains(option);
                return FilterChip(
                  label: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        currentSelected.add(option);
                      } else {
                        currentSelected.remove(option);
                      }
                      dataMap[field.id] = currentSelected;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
        break;
      case FieldType.checkboxListWithQuantity:
        Map<String, dynamic> currentSelectedQ = {};
        if (dataMap[field.id] != null && dataMap[field.id] is Map) {
          currentSelectedQ = Map<String, dynamic>.from(dataMap[field.id]);
        }
        mainWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label + (field.isRequired ? ' *' : ''), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 5),
            Column(
              children: (field.options ?? []).map((option) {
                final isSelected = currentSelectedQ.containsKey(option);
                return Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      fillColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? Theme.of(context).primaryColor : Colors.transparent),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            currentSelectedQ[option] = '1';
                          } else {
                            currentSelectedQ.remove(option);
                          }
                          dataMap[field.id] = currentSelectedQ;
                        });
                      },
                    ),
                    Expanded(child: Text(option, style: const TextStyle(color: Colors.black87))),
                    if (isSelected && !option.toLowerCase().contains('otro')) 
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: currentSelectedQ[option]?.toString() ?? '1',
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                              labelText: 'Cantidad',
                              isDense: true,
                              labelStyle: const TextStyle(color: Colors.black54),
                              filled: true,
                              fillColor: Colors.grey.shade50),
                          onChanged: (v) => currentSelectedQ[option] = v,
                          onSaved: (v) => currentSelectedQ[option] = v,
                        )
                      )
                  ],
                );
              }).toList(),
            ),
          ],
        );
        break;
      default:
        mainWidget = const SizedBox();
    }

    if (showOtrosField) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainWidget,
          const SizedBox(height: 8),
          TextFormField(
            initialValue: dataMap['${field.id}_otros']?.toString() ?? '',
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
                labelText: 'Mencionar detalle de "Otro/s"',
                labelStyle: const TextStyle(color: Colors.black54),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50
            ),
            onChanged: (v) => dataMap['${field.id}_otros'] = v,
            onSaved: (v) => dataMap['${field.id}_otros'] = v,
          ),
        ],
      );
    }

    return mainWidget;
  }
}
