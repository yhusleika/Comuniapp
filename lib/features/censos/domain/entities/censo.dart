import 'package:equatable/equatable.dart';

class Censo extends Equatable {
  final String id;
  final String nombre;
  final String zona;
  final String responsable;
  final DateTime fecha;

  const Censo({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.responsable,
    required this.fecha,
  });

  @override
  List<Object?> get props => [id, nombre, zona, responsable, fecha];
}
