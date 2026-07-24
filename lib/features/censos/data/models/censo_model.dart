import 'package:hive/hive.dart';
import '../../domain/entities/censo.dart';

part 'censo_model.g.dart';

@HiveType(typeId: 5)
class CensoModel extends Censo {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String nombre;

  @HiveField(2)
  @override
  final String zona;

  @HiveField(3)
  @override
  final String responsable;

  @HiveField(4)
  @override
  final DateTime fecha;

  @HiveField(5, defaultValue: [])
  @override
  final List<String> camposSeleccionados;

  @HiveField(6, defaultValue: false)
  @override
  final bool isSynced;

  const CensoModel({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.responsable,
    required this.fecha,
    required this.camposSeleccionados,
    this.isSynced = false,
  }) : super(
            id: id,
            nombre: nombre,
            zona: zona,
            responsable: responsable,
            fecha: fecha,
            camposSeleccionados: camposSeleccionados,
            isSynced: isSynced);

  factory CensoModel.fromEntity(Censo entity) {
    return CensoModel(
      id: entity.id,
      nombre: entity.nombre,
      zona: entity.zona,
      responsable: entity.responsable,
      fecha: entity.fecha,
      camposSeleccionados: entity.camposSeleccionados,
      isSynced: entity.isSynced,
    );
  }

  Censo toEntity() {
    return Censo(
      id: id,
      nombre: nombre,
      zona: zona,
      responsable: responsable,
      fecha: fecha,
      camposSeleccionados: camposSeleccionados,
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'zona': zona,
      'responsable': responsable,
      'fecha': fecha.toIso8601String(),
      'camposSeleccionados': camposSeleccionados,
      'isSynced': isSynced,
    };
  }

  factory CensoModel.fromJson(Map<String, dynamic> json) {
    return CensoModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      zona: json['zona'] ?? '',
      responsable: json['responsable'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      camposSeleccionados: json['camposSeleccionados'] != null ? List<String>.from(json['camposSeleccionados']) : [],
      isSynced: true,
    );
  }
}
