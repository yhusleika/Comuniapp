import 'package:hive/hive.dart';
import '../../domain/entities/ayuda_type.dart';

part 'ayuda_type_model.g.dart';

@HiveType(typeId: 4)
class AyudaTypeModel extends AyudaType {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String nombre;

  @HiveField(2)
  @override
  final String responsable;

  @HiveField(3)
  @override
  final String descripcion;

  const AyudaTypeModel({
    required this.id,
    required this.nombre,
    required this.responsable,
    this.descripcion = '',
  }) : super(id: id, nombre: nombre, responsable: responsable, descripcion: descripcion);

  factory AyudaTypeModel.fromEntity(AyudaType entity) {
    return AyudaTypeModel(
      id: entity.id,
      nombre: entity.nombre,
      responsable: entity.responsable,
      descripcion: entity.descripcion,
    );
  }

  AyudaType toEntity() {
    return AyudaType(
      id: id,
      nombre: nombre,
      responsable: responsable,
      descripcion: descripcion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'responsable': responsable,
      'descripcion': descripcion,
    };
  }

  factory AyudaTypeModel.fromJson(Map<String, dynamic> json) {
    return AyudaTypeModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      responsable: json['responsable'] ?? '',
      descripcion: json['descripcion'] ?? '',
    );
  }
}
