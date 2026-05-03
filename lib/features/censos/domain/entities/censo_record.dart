import 'package:equatable/equatable.dart';

class CensoRecord extends Equatable {
  final String id;
  final String censoId;
  final String jefeFamilia;
  final String cedula;
  final String direccion;
  final int numeroHijos;
  final String estatus; // Censado, Pendiente, Casos Especiales
  final Map<String, dynamic> datosDinamicos;

  const CensoRecord({
    required this.id,
    required this.censoId,
    required this.jefeFamilia,
    required this.cedula,
    required this.direccion,
    required this.numeroHijos,
    required this.estatus,
    this.datosDinamicos = const {},
  });

  @override
  List<Object?> get props =>
      [id, censoId, jefeFamilia, cedula, direccion, numeroHijos, estatus, datosDinamicos];
}
