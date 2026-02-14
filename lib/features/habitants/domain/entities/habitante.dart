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
  final String condicionVivienda; // Propia, Alquilada, etc.
  final String tipoVivienda; // Casa, Apartamento, Rancho, etc.
  final String registeredBy; // ID del vocero
  final DateTime fechaRegistro;
  final bool isSynced;

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
    this.isSynced = false,
  });

  @override
  List<Object> get props => [id, cedula, nombres, apellidos, isSynced];
}
