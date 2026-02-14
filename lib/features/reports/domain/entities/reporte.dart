import 'package:equatable/equatable.dart';

class Reporte extends Equatable {
  final String id;
  final String titulo;
  final String descripcion;
  final String tipo; // Agua, Electricidad, Aseo, Otros
  final String prioridad; // Critica, Alta, Media, Baja
  final String estatus; // Pendiente, En Proceso, Resuelto
  final List<String> fotosPaths; // Local paths
  final double latitud;
  final double longitud;
  final String createdBy;
  final DateTime fechaRegistro;
  final bool isSynced;

  const Reporte({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.prioridad,
    this.estatus = 'Pendiente',
    this.fotosPaths = const [],
    this.latitud = 0.0,
    this.longitud = 0.0,
    required this.createdBy,
    required this.fechaRegistro,
    this.isSynced = false,
  });

  @override
  List<Object> get props => [id, titulo, estatus, isSynced];
}
