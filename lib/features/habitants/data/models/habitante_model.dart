import 'package:hive/hive.dart';
import '../../domain/entities/habitante.dart';

part 'habitante_model.g.dart';

@HiveType(typeId: 1)
class HabitanteModel extends Habitante {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String cedula;
  @override
  @HiveField(2)
  final String nombres;
  @override
  @HiveField(3)
  final String apellidos;
  @override
  @HiveField(4)
  final String telefono;
  @override
  @HiveField(5)
  final String sector;
  @override
  @HiveField(6)
  final String puntoReferencia;
  @override
  @HiveField(7)
  final bool tieneDiscapacidad;
  @override
  @HiveField(8)
  final String detallesDiscapacidad;
  @override
  @HiveField(9)
  final bool tieneEnfermedadCronica;
  @override
  @HiveField(10)
  final String detallesEnfermedad;
  @override
  @HiveField(11)
  final String condicionVivienda;
  @override
  @HiveField(12)
  final String tipoVivienda;
  @override
  @HiveField(13)
  final String registeredBy;
  @override
  @HiveField(14)
  final DateTime fechaRegistro;
  @override
  @HiveField(15)
  final bool isSynced;
  @override
  @HiveField(16)
  final String ayudaRecibida;

  const HabitanteModel({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.sector,
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
    this.ayudaRecibida = '',
  }) : super(
          id: id,
          cedula: cedula,
          nombres: nombres,
          apellidos: apellidos,
          telefono: telefono,
          sector: sector,
          ayudaRecibida: ayudaRecibida,
          puntoReferencia: puntoReferencia,
          tieneDiscapacidad: tieneDiscapacidad,
          detallesDiscapacidad: detallesDiscapacidad,
          tieneEnfermedadCronica: tieneEnfermedadCronica,
          detallesEnfermedad: detallesEnfermedad,
          condicionVivienda: condicionVivienda,
          tipoVivienda: tipoVivienda,
          registeredBy: registeredBy,
          fechaRegistro: fechaRegistro,
          isSynced: isSynced,
        );

  factory HabitanteModel.fromEntity(Habitante habitante) {
    return HabitanteModel(
      id: habitante.id,
      cedula: habitante.cedula,
      nombres: habitante.nombres,
      apellidos: habitante.apellidos,
      telefono: habitante.telefono,
      sector: habitante.sector,
      ayudaRecibida: habitante.ayudaRecibida,
      puntoReferencia: habitante.puntoReferencia,
      tieneDiscapacidad: habitante.tieneDiscapacidad,
      detallesDiscapacidad: habitante.detallesDiscapacidad,
      tieneEnfermedadCronica: habitante.tieneEnfermedadCronica,
      detallesEnfermedad: habitante.detallesEnfermedad,
      condicionVivienda: habitante.condicionVivienda,
      tipoVivienda: habitante.tipoVivienda,
      registeredBy: habitante.registeredBy,
      fechaRegistro: habitante.fechaRegistro,
      isSynced: habitante.isSynced,
    );
  }
}
