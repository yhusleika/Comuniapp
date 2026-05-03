import 'package:equatable/equatable.dart';

class AyudaType extends Equatable {
  final String id;
  final String nombre;
  final String responsable;

  const AyudaType({
    required this.id,
    required this.nombre,
    required this.responsable,
  });

  @override
  List<Object?> get props => [id, nombre, responsable];
}
