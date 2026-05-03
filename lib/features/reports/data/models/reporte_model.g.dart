// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reporte_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReporteModelAdapter extends TypeAdapter<ReporteModel> {
  @override
  final int typeId = 2;

  @override
  ReporteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReporteModel(
      id: fields[0] as String,
      titulo: fields[1] as String,
      descripcion: fields[2] as String,
      tipo: fields[3] as String,
      prioridad: fields[4] as String,
      estatus: fields[5] as String,
      fotosPaths: (fields[6] as List).cast<String>(),
      latitud: fields[7] as double,
      longitud: fields[8] as double,
      createdBy: fields[9] as String,
      fechaRegistro: fields[10] as DateTime,
      isSynced: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReporteModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titulo)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.tipo)
      ..writeByte(4)
      ..write(obj.prioridad)
      ..writeByte(5)
      ..write(obj.estatus)
      ..writeByte(6)
      ..write(obj.fotosPaths)
      ..writeByte(7)
      ..write(obj.latitud)
      ..writeByte(8)
      ..write(obj.longitud)
      ..writeByte(9)
      ..write(obj.createdBy)
      ..writeByte(10)
      ..write(obj.fechaRegistro)
      ..writeByte(11)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReporteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
