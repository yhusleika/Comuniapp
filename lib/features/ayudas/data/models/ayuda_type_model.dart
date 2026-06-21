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

  const AyudaTypeModel({
    required this.id,
    required this.nombre,
    required this.responsable,
  }) : super(id: id, nombre: nombre, responsable: responsable);

  factory AyudaTypeModel.fromEntity(AyudaType entity) {
    return AyudaTypeModel(
      id: entity.id,
      nombre: entity.nombre,
      responsable: entity.responsable,
    );
  }

  AyudaType toEntity() {
    return AyudaType(
      id: id,
      nombre: nombre,
      responsable: responsable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'responsable': responsable,
    };
  }

  factory AyudaTypeModel.fromJson(Map<String, dynamic> json) {
    return AyudaTypeModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      responsable: json['responsable'] ?? '',
    );
  }
}
