// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'censo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CensoModelAdapter extends TypeAdapter<CensoModel> {
  @override
  final int typeId = 5;

  @override
  CensoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CensoModel(
      id: fields[0] as String,
      nombre: fields[1] as String,
      zona: fields[2] as String,
      responsable: fields[3] as String,
      fecha: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CensoModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.zona)
      ..writeByte(3)
      ..write(obj.responsable)
      ..writeByte(4)
      ..write(obj.fecha);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CensoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
