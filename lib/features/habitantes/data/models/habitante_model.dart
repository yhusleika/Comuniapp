import 'package:hive/hive.dart';
import '../../domain/entities/habitante.dart';

part 'habitante_model.g.dart';

@HiveType(typeId: 1)
class HabitanteModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String cedula;
  @HiveField(2)
  final String nombres;
  @HiveField(3)
  final String apellidos;
  @HiveField(4)
  final String telefono;
  @HiveField(5)
  final String sector;
  @HiveField(6)
  final String puntoReferencia;
  @HiveField(7)
  final bool tieneDiscapacidad;
  @HiveField(8)
  final String detallesDiscapacidad;
  @HiveField(9)
  final bool tieneEnfermedadCronica;
  @HiveField(10)
  final String detallesEnfermedad;
  @HiveField(11)
  final String condicionVivienda;
  @HiveField(12)
  final String tipoVivienda;
  @HiveField(13)
  final String registeredBy;
  @HiveField(14)
  final DateTime fechaRegistro;
  @HiveField(15)
  final bool isSynced;
  @HiveField(16)
  final String ayudaRecibida;
  @HiveField(17)
  final DateTime? fechaNacimiento;
  @HiveField(18)
  final String genero;

  HabitanteModel({
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
    this.fechaNacimiento,
    this.genero = '',
    this.isSynced = false,
    this.ayudaRecibida = '',
  });

  Habitante toEntity() => Habitante(
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
        fechaNacimiento: fechaNacimiento,
        genero: genero,
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
      fechaNacimiento: habitante.fechaNacimiento,
      genero: habitante.genero,
    );
  }

  HabitanteModel copyWith({bool? isSynced}) {
    return HabitanteModel(
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
      fechaNacimiento: fechaNacimiento,
      genero: genero,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'sector': sector,
      'puntoReferencia': puntoReferencia,
      'tieneDiscapacidad': tieneDiscapacidad,
      'detallesDiscapacidad': detallesDiscapacidad,
      'tieneEnfermedadCronica': tieneEnfermedadCronica,
      'detallesEnfermedad': detallesEnfermedad,
      'condicionVivienda': condicionVivienda,
      'tipoVivienda': tipoVivienda,
      'registeredBy': registeredBy,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      'genero': genero,
      'isSynced': isSynced,
      'ayudaRecibida': ayudaRecibida,
    };
  }

  factory HabitanteModel.fromJson(Map<String, dynamic> json) {
    return HabitanteModel(
      id: json['id'] ?? '',
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      telefono: json['telefono'] ?? '',
      sector: json['sector'] ?? '',
      puntoReferencia: json['puntoReferencia'] ?? '',
      tieneDiscapacidad: json['tieneDiscapacidad'] ?? false,
      detallesDiscapacidad: json['detallesDiscapacidad'] ?? '',
      tieneEnfermedadCronica: json['tieneEnfermedadCronica'] ?? false,
      detallesEnfermedad: json['detallesEnfermedad'] ?? '',
      condicionVivienda: json['condicionVivienda'] ?? '',
      tipoVivienda: json['tipoVivienda'] ?? '',
      registeredBy: json['registeredBy'] ?? '',
      fechaRegistro: DateTime.tryParse(json['fechaRegistro'] ?? '') ?? DateTime.now(),
      fechaNacimiento: json['fechaNacimiento'] != null ? DateTime.tryParse(json['fechaNacimiento']) : null,
      genero: json['genero'] ?? '',
      isSynced: true,
      ayudaRecibida: json['ayudaRecibida'] ?? '',
    );
  }
}
