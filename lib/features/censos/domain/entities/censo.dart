import 'package:equatable/equatable.dart';

class Censo extends Equatable {
  final String id;
  final String nombre;
  final String zona;
  final String responsable;
  final DateTime fecha;
  final List<String> camposSeleccionados;
  final bool isSynced;

  const Censo({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.responsable,
    required this.fecha,
    this.camposSeleccionados = const [],
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [id, nombre, zona, responsable, fecha, camposSeleccionados, isSynced];
}
