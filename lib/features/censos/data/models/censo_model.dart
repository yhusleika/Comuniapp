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

  const CensoModel({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.responsable,
    required this.fecha,
    required this.camposSeleccionados,
  }) : super(
            id: id,
            nombre: nombre,
            zona: zona,
            responsable: responsable,
            fecha: fecha,
            camposSeleccionados: camposSeleccionados);

  factory CensoModel.fromEntity(Censo entity) {
    return CensoModel(
      id: entity.id,
      nombre: entity.nombre,
      zona: entity.zona,
      responsable: entity.responsable,
      fecha: entity.fecha,
      camposSeleccionados: entity.camposSeleccionados,
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
    );
  }
}
