import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/habitante.dart';
import '../bloc/habitants_bloc.dart';
import '../../../../shared/helpers/sectores_helper.dart';

class HabitanteFormDialog extends StatefulWidget {
  final Habitante? habitante;
  final void Function(Habitante)? onSave;

  const HabitanteFormDialog({
    super.key,
    this.habitante,
    this.onSave,
  });

  static Future<Habitante?> show(
    BuildContext context, {
    Habitante? habitante,
    void Function(Habitante)? onSave,
  }) {
    HabitantsBloc? bloc;
    try {
      bloc = context.read<HabitantsBloc>();
    } catch (_) {}

    final widget = HabitanteFormDialog(
      habitante: habitante,
      onSave: onSave,
    );

    return showDialog<Habitante>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => bloc != null
          ? BlocProvider.value(value: bloc, child: widget)
          : widget,
    );
  }

  @override
  State<HabitanteFormDialog> createState() => _HabitanteFormDialogState();
}

class _HabitanteFormDialogState extends State<HabitanteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _ptoRefCtrl;
  late final TextEditingController _birthDateCtrl;
  late final TextEditingController _detallesDiscapacidadCtrl;
  late final TextEditingController _detallesEnfermedadCtrl;

  DateTime? _selectedBirthDate;
  String _sexo = '';
  String _zona = 'Sector 1';
  String _ayuda = 'Ninguna';
  String _condVivienda = 'Propia';
  String _tipoVivienda = 'Casa';
  bool _tieneDiscapacidad = false;
  bool _tieneEnfermedad = false;

  List<String> _dynamicSectores = SectoresHelper.defaultSectores;
  static const _condiciones = ['Propia', 'Alquilada', 'Prestada', 'Otra'];
  static const _tipos = ['Casa', 'Apartamento', 'Rancho', 'Habitación'];

  bool get _isEditing => widget.habitante != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habitante;
    _nombresCtrl = TextEditingController(text: h?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: h?.apellidos ?? '');
    _cedulaCtrl = TextEditingController(text: h?.cedula ?? '');
    _cedulaCtrl.addListener(_onCedulaChanged);
    _telefonoCtrl = TextEditingController(text: h?.telefono ?? '');
    _ptoRefCtrl = TextEditingController(text: h?.puntoReferencia ?? '');
    _sexo = h?.sexo ?? '';
    _selectedBirthDate = h?.fechaNacimiento;
    _birthDateCtrl = TextEditingController(
      text: _selectedBirthDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
          : '',
    );
    _detallesDiscapacidadCtrl =
        TextEditingController(text: h?.detallesDiscapacidad ?? '');
    _detallesEnfermedadCtrl =
        TextEditingController(text: h?.detallesEnfermedad ?? '');
    _zona = h?.sector ?? 'Sector 1 - Centro';
    _ayuda = (h?.ayudaRecibida.isEmpty ?? true) ? 'Ninguna' : h!.ayudaRecibida;
    _condVivienda = h?.condicionVivienda ?? 'Propia';
    _tipoVivienda = h?.tipoVivienda ?? 'Casa';
    _tieneDiscapacidad = h?.tieneDiscapacidad ?? false;
    _tieneEnfermedad = h?.tieneEnfermedadCronica ?? false;
    _loadSectores();
  }

  void _onCedulaChanged() {
    if (mounted) setState(() {});
  }

  String? _getParentChildLabel(String input, List<Habitante> habitants) {
    final trimmed = input.trim();
    if (!trimmed.contains('-')) return null;

    final parts = trimmed.split('-');
    final parentCed = parts.first.trim();
    if (parentCed.isEmpty) return null;

    for (final h in habitants) {
      if (h.cedula.trim() == parentCed) {
        final pNombre = h.nombres.trim().split(' ').first;
        final pApellido = h.apellidos.trim().split(' ').first;
        return '(hijo de $pNombre $pApellido)';
      }
    }
    return '(hijo de C.I. $parentCed)';
  }

  Future<void> _loadSectores() async {
    final list = await SectoresHelper.getAvailableSectores();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _dynamicSectores = list;
        if (!_dynamicSectores.contains(_zona)) {
          _dynamicSectores.insert(0, _zona);
        }
      });
    }
  }

  @override
  void dispose() {
    _cedulaCtrl.removeListener(_onCedulaChanged);
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _ptoRefCtrl.dispose();
    _birthDateCtrl.dispose();
    _detallesDiscapacidadCtrl.dispose();
    _detallesEnfermedadCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final newH = Habitante(
      id: widget.habitante?.id ?? const Uuid().v4(),
      cedula: _cedulaCtrl.text.trim(),
      nombres: _nombresCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      sector: _zona,
      ayudaRecibida: _ayuda == 'Ninguna' ? '' : _ayuda,
      puntoReferencia: _ptoRefCtrl.text.trim(),
      tieneDiscapacidad: _tieneDiscapacidad,
      detallesDiscapacidad: _detallesDiscapacidadCtrl.text.trim(),
      tieneEnfermedadCronica: _tieneEnfermedad,
      detallesEnfermedad: _detallesEnfermedadCtrl.text.trim(),
      condicionVivienda: _condVivienda,
      tipoVivienda: _tipoVivienda,
      registeredBy: widget.habitante?.registeredBy ?? 'admin',
      fechaRegistro: widget.habitante?.fechaRegistro ?? DateTime.now(),
      fechaNacimiento: _selectedBirthDate,
      sexo: _sexo,
    );

    if (widget.onSave != null) {
      widget.onSave!(newH);
    } else {
      context.read<HabitantsBloc>().add(
            _isEditing ? UpdateHabitanteEvent(newH) : CreateHabitante(newH),
          );
    }
    Navigator.pop(context, newH);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    List<Habitante> allHabitants = [];
    try {
      final hState = context.watch<HabitantsBloc>().state;
      if (hState is HabitantsLoaded) {
        allHabitants = hState.habitants;
      }
    } catch (_) {}
    final parentLabel = _getParentChildLabel(_cedulaCtrl.text, allHabitants);

    return Dialog(
      alignment: isMobile ? Alignment.bottomCenter : Alignment.center,
      insetPadding: isMobile ? const EdgeInsets.only(top: 40) : const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: isMobile 
          ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
          : BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(20),
                  bottom: isMobile ? Radius.zero : Radius.zero,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note : Icons.person_add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar Habitante' : 'Nuevo Habitante',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Formulario
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Datos Personales'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field(_nombresCtrl, 'Nombres', Icons.person, required: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _field(_apellidosCtrl, 'Apellidos', Icons.person_outline, required: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _cedulaCtrl,
                              'Cédula *',
                              Icons.badge,
                              required: true,
                              keyboardType: TextInputType.text,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'La Cédula es obligatoria' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _telefonoCtrl,
                              'Teléfono',
                              Icons.phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 11,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length != 11) {
                                  return 'Debe tener exactamente 11 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (parentLabel != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            parentLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedBirthDate ?? DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedBirthDate = picked;
                                    _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: _field(_birthDateCtrl, 'Fecha de Nacimiento', Icons.cake),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              value: _sexo,
                              decoration: InputDecoration(
                                labelText: 'Sexo',
                                prefixIcon: const Icon(Icons.wc, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Seleccionar...')),
                                DropdownMenuItem(value: 'hombre', child: Text('Hombre')),
                                DropdownMenuItem(value: 'mujer', child: Text('Mujer')),
                              ],
                              onChanged: (v) => setState(() => _sexo = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(_ptoRefCtrl, 'Punto de Referencia', Icons.location_on),
                      const SizedBox(height: 20),

                      _sectionLabel('Clasificación'),
                      const SizedBox(height: 12),
                      _dropdown('Sector', _dynamicSectores, _zona, (v) => setState(() => _zona = v!)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _dropdown('Condición Vivienda', _condiciones, _condVivienda, (v) => setState(() => _condVivienda = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _dropdown('Tipo Vivienda', _tipos, _tipoVivienda, (v) => setState(() => _tipoVivienda = v!))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Condición de Salud'),
                      const SizedBox(height: 8),
                      _switchRow(
                        'Tiene Discapacidad',
                        _tieneDiscapacidad,
                        (v) => setState(() => _tieneDiscapacidad = v),
                      ),
                      if (_tieneDiscapacidad) ...[
                        const SizedBox(height: 8),
                        _field(_detallesDiscapacidadCtrl, 'Detalle de Discapacidad', Icons.info_outline),
                      ],
                      const SizedBox(height: 8),
                      _switchRow(
                        'Tiene Enfermedad Crónica',
                        _tieneEnfermedad,
                        (v) => setState(() => _tieneEnfermedad = v),
                      ),
                      if (_tieneEnfermedad) ...[
                        const SizedBox(height: 8),
                        _field(_detallesEnfermedadCtrl, 'Detalle de Enfermedad', Icons.medical_information_outlined),
                      ],
                      const SizedBox(height: 24),

                      // Acciones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submit,
                              icon: Icon(_isEditing ? Icons.save : Icons.add),
                              label: Text(_isEditing ? 'Guardar Cambios' : 'Agregar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        counterText: '',
      ),
      validator: validator ?? (required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null
          : null),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    final List<String> effectiveItems = items.contains(value) ? items : [value, ...items];
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: effectiveItems
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _switchRow(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
