import 'package:hive/hive.dart';
import '../../domain/entities/censo_record.dart';

part 'censo_record_model.g.dart';

@HiveType(typeId: 6)
class CensoRecordModel extends CensoRecord {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String censoId;

  @HiveField(2)
  @override
  final String jefeFamilia;

  @HiveField(3)
  @override
  final String cedula;

  @HiveField(4)
  @override
  final String direccion;

  @HiveField(5)
  @override
  final int numeroHijos;

  @HiveField(6)
  @override
  final String estatus;

  @HiveField(7, defaultValue: {})
  @override
  final Map<String, dynamic> datosDinamicos;

  const CensoRecordModel({
    required this.id,
    required this.censoId,
    required this.jefeFamilia,
    required this.cedula,
    required this.direccion,
    required this.numeroHijos,
    required this.estatus,
    required this.datosDinamicos,
  }) : super(
          id: id,
          censoId: censoId,
          jefeFamilia: jefeFamilia,
          cedula: cedula,
          direccion: direccion,
          numeroHijos: numeroHijos,
          estatus: estatus,
          datosDinamicos: datosDinamicos,
        );

  factory CensoRecordModel.fromEntity(CensoRecord entity) {
    return CensoRecordModel(
      id: entity.id,
      censoId: entity.censoId,
      jefeFamilia: entity.jefeFamilia,
      cedula: entity.cedula,
      direccion: entity.direccion,
      numeroHijos: entity.numeroHijos,
      estatus: entity.estatus,
      datosDinamicos: entity.datosDinamicos,
    );
  }

  CensoRecord toEntity() {
    return CensoRecord(
      id: id,
      censoId: censoId,
      jefeFamilia: jefeFamilia,
      cedula: cedula,
      direccion: direccion,
      numeroHijos: numeroHijos,
      estatus: estatus,
      datosDinamicos: datosDinamicos,
    );
  }
}
