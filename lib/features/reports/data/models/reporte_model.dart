import 'package:hive/hive.dart';
import '../../domain/entities/reporte.dart';

part 'reporte_model.g.dart';

@HiveType(typeId: 2)
class ReporteModel extends Reporte {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String titulo;
  @override
  @HiveField(2)
  final String descripcion;
  @override
  @HiveField(3)
  final String tipo;
  @override
  @HiveField(4)
  final String prioridad;
  @override
  @HiveField(5)
  final String estatus;
  @override
  @HiveField(6)
  final List<String> fotosPaths;
  @override
  @HiveField(7)
  final double latitud;
  @override
  @HiveField(8)
  final double longitud;
  @override
  @HiveField(9)
  final String createdBy;
  @override
  @HiveField(10)
  final DateTime fechaRegistro;
  @override
  @HiveField(11)
  final bool isSynced;

  const ReporteModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.prioridad,
    required this.estatus,
    required this.fotosPaths,
    required this.latitud,
    required this.longitud,
    required this.createdBy,
    required this.fechaRegistro,
    this.isSynced = false,
  }) : super(
          id: id,
          titulo: titulo,
          descripcion: descripcion,
          tipo: tipo,
          prioridad: prioridad,
          estatus: estatus,
          fotosPaths: fotosPaths,
          latitud: latitud,
          longitud: longitud,
          createdBy: createdBy,
          fechaRegistro: fechaRegistro,
          isSynced: isSynced,
        );

  factory ReporteModel.fromEntity(Reporte reporte) {
    return ReporteModel(
      id: reporte.id,
      titulo: reporte.titulo,
      descripcion: reporte.descripcion,
      tipo: reporte.tipo,
      prioridad: reporte.prioridad,
      estatus: reporte.estatus,
      fotosPaths: reporte.fotosPaths,
      latitud: reporte.latitud,
      longitud: reporte.longitud,
      createdBy: reporte.createdBy,
      fechaRegistro: reporte.fechaRegistro,
      isSynced: reporte.isSynced,
    );
  }
}
