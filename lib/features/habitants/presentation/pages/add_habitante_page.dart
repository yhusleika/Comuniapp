import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/habitante.dart';
import '../bloc/habitants_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/helpers/sectores_helper.dart';

class AddHabitantePage extends StatefulWidget {
  const AddHabitantePage({super.key});

  @override
  State<AddHabitantePage> createState() => _AddHabitantePageState();
}

class _AddHabitantePageState extends State<AddHabitantePage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _puntoRefCtrl = TextEditingController();
  final _detallesDiscapacidadCtrl = TextEditingController();
  final _detallesEnfermedadCtrl = TextEditingController();
  
  bool _tieneDiscapacidad = false;
  bool _tieneEnfermedad = false;
  String _condicionVivienda = 'Propia';
  String _tipoVivienda = 'Casa';
  List<String> _sectoresDisponibles = SectoresHelper.defaultSectores;
  String _selectedSector = SectoresHelper.defaultSectores.first;

  @override
  void initState() {
    super.initState();
    _sectorCtrl.text = _selectedSector;
    _loadSectores();
  }

  Future<void> _loadSectores() async {
    final list = await SectoresHelper.getAvailableSectores();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _sectoresDisponibles = list;
        _selectedSector = list.first;
        _sectorCtrl.text = _selectedSector;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Habitante')),
      body: BlocListener<HabitantsBloc, HabitantsState>(
        listener: (context, state) {
          if (state is HabitanteOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Habitante registrado correctamente')),
            );
            Navigator.pop(context);
          } else if (state is HabitantsError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep += 1);
              } else {
                 if (_formKey.currentState!.validate()) {
                   final habitante = Habitante(
                     id: const Uuid().v4(),
                     cedula: _cedulaCtrl.text,
                     nombres: _nombresCtrl.text,
                     apellidos: _apellidosCtrl.text,
                     telefono: _telefonoCtrl.text,
                     sector: _sectorCtrl.text,
                     puntoReferencia: _puntoRefCtrl.text,
                     tieneDiscapacidad: _tieneDiscapacidad,
                     detallesDiscapacidad: _detallesDiscapacidadCtrl.text,
                     tieneEnfermedadCronica: _tieneEnfermedad,
                     detallesEnfermedad: _detallesEnfermedadCtrl.text,
                     condicionVivienda: _condicionVivienda,
                     tipoVivienda: _tipoVivienda,
                     registeredBy: 'current_user_id', // Should get from AuthBloc
                     fechaRegistro: DateTime.now(),
                   );
                   context.read<HabitantsBloc>().add(CreateHabitante(habitante));
                 }
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              } else {
                Navigator.pop(context);
              }
            },
            steps: [
              Step(
                title: const Text('Datos Personales'),
                content: Column(
                  children: [
                    TextFormField(controller: _cedulaCtrl, decoration: const InputDecoration(labelText: 'Cédula')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos')),
                    const SizedBox(height: 8),
                    TextFormField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                  ],
                ),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text('Vivienda'),
                content: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _sectoresDisponibles.contains(_selectedSector) ? _selectedSector : _sectoresDisponibles.first,
                      items: _sectoresDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedSector = v;
                            _sectorCtrl.text = v;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Sector'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(controller: _puntoRefCtrl, decoration: const InputDecoration(labelText: 'Punto Referencia')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _condicionVivienda,
                      items: ['Propia', 'Alquilada', 'Prestada', 'Invadida'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _condicionVivienda = v!),
                      decoration: const InputDecoration(labelText: 'Condición'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _tipoVivienda,
                      items: ['Casa', 'Apartamento', 'Rancho', 'Anexo'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _tipoVivienda = v!),
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                  ],
                ),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text('Salud'),
                content: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('¿Tiene Discapacidad?'),
                      value: _tieneDiscapacidad,
                      onChanged: (v) => setState(() => _tieneDiscapacidad = v),
                    ),
                    if (_tieneDiscapacidad)
                      TextFormField(controller: _detallesDiscapacidadCtrl, decoration: const InputDecoration(labelText: 'Detalles Discapacidad')),
                    SwitchListTile(
                      title: const Text('¿Enfermedad Crónica?'),
                      value: _tieneEnfermedad,
                      onChanged: (v) => setState(() => _tieneEnfermedad = v),
                    ),
                    if (_tieneEnfermedad)
                      TextFormField(controller: _detallesEnfermedadCtrl, decoration: const InputDecoration(labelText: 'Detalles Enfermedad')),
                  ],
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
