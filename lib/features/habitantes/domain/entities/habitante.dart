import 'package:equatable/equatable.dart';

class Habitante extends Equatable {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String sector;
  final String ayudaRecibida;
  final String puntoReferencia;
  final bool tieneDiscapacidad;
  final String detallesDiscapacidad;
  final bool tieneEnfermedadCronica;
  final String detallesEnfermedad;
  final String condicionVivienda;
  final String tipoVivienda;
  final String registeredBy;
  final DateTime fechaRegistro;
  final DateTime? fechaNacimiento;
  final String genero;

  const Habitante({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.sector,
    this.ayudaRecibida = '',
    required this.puntoReferencia,
    required this.tieneDiscapacidad,
    this.detallesDiscapacidad = '',
    required this.tieneEnfermedadCronica,
    this.detallesEnfermedad = '',
    required this.condicionVivienda,
    required this.tipoVivienda,
    required this.registeredBy,
    required this.fechaRegistro,
    this.fechaNacimiento,
    this.genero = '',
  });

  @override
  List<Object?> get props => [id, cedula, nombres, apellidos, telefono, sector, ayudaRecibida, puntoReferencia, tieneDiscapacidad, detallesDiscapacidad, tieneEnfermedadCronica, detallesEnfermedad, condicionVivienda, tipoVivienda, registeredBy, fechaRegistro, fechaNacimiento, genero];
}
