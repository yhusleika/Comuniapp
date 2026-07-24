import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../domain/entities/reporte.dart';
import '../bloc/reports_bloc.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  
  String _tipo = 'Agua';
  String _prioridad = 'Media';
  String? _imagePath;
  bool _isCompressing = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      if (kIsWeb) {
        setState(() {
          _imagePath = photo.path;
        });
      } else {
        setState(() => _isCompressing = true);
        // Compress
        final compressedPath = await sl<ImageCompressionService>().saveCompressedImage(File(photo.path));
        
        setState(() {
          _imagePath = compressedPath;
          _isCompressing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Nuevo Reporte')),
        body: BlocListener<ReportsBloc, ReportsState>(
          listener: (context, state) {
            if (state is ReportOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte creado exitosamente')),
              );
              Navigator.pop(context);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _imagePath != null
                          ? (kIsWeb
                              ? Image.network(_imagePath!, fit: BoxFit.cover)
                              : Image.file(File(_imagePath!), fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]),
                                const Text('Toca para tomar foto'),
                              ],
                            ),
                    ),
                  ),
                  if (_isCompressing) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título del Problema'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción detallada'),
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo de Servicio'),
                    items: ['Agua', 'Electricidad', 'Aseo', 'Gas', 'Vialidad', 'Otros']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _prioridad,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: ['Baja', 'Media', 'Alta', 'Critica']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _prioridad = v!),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final reporte = Reporte(
                          id: const Uuid().v4(),
                          titulo: _tituloCtrl.text,
                          descripcion: _descripcionCtrl.text,
                          tipo: _tipo,
                          prioridad: _prioridad,
                          fotosPaths: _imagePath != null ? [_imagePath!] : [],
                          createdBy: 'current_user_id',
                          fechaRegistro: DateTime.now(),
                          latitud: 0.0, // Should implement Geolocator, keeping simple for now
                          longitud: 0.0,
                        );
                        context.read<ReportsBloc>().add(CreateReportRequested(reporte));
                      }
                    },
                    child: const Text('Enviar Reporte'),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
