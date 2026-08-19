import 'package:hive/hive.dart';
import '../../domain/entities/reporte.dart';

part 'reporte_model.g.dart';

@HiveType(typeId: 2)
class ReporteModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String titulo;
  @HiveField(2)
  final String descripcion;
  @HiveField(3)
  final String tipo;
  @HiveField(4)
  final String prioridad;
  @HiveField(5)
  final String estatus;
  @HiveField(6)
  final List<String> fotosPaths;
  @HiveField(7)
  final double latitud;
  @HiveField(8)
  final double longitud;
  @HiveField(9)
  final String createdBy;
  @HiveField(10)
  final DateTime fechaRegistro;
  @HiveField(11)
  final bool isSynced;

  ReporteModel({
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
  });

  Reporte toEntity() => Reporte(
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
    );
  }

  ReporteModel copyWith({bool? isSynced}) {
    return ReporteModel(
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
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'prioridad': prioridad,
      'estatus': estatus,
      'fotosPaths': fotosPaths,
      'latitud': latitud,
      'longitud': longitud,
      'createdBy': createdBy,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory ReporteModel.fromJson(Map<String, dynamic> json) {
    return ReporteModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tipo: json['tipo'] ?? '',
      prioridad: json['prioridad'] ?? '',
      estatus: json['estatus'] ?? '',
      fotosPaths: json['fotosPaths'] != null ? List<String>.from(json['fotosPaths']) : [],
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      createdBy: json['createdBy'] ?? '',
      fechaRegistro: DateTime.tryParse(json['fechaRegistro'] ?? '') ?? DateTime.now(),
      isSynced: true,
    );
  }
}
