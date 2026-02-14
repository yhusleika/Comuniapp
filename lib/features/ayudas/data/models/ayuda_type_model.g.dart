// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayuda_type_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AyudaTypeModelAdapter extends TypeAdapter<AyudaTypeModel> {
  @override
  final int typeId = 4;

  @override
  AyudaTypeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AyudaTypeModel(
      id: fields[0] as String,
      nombre: fields[1] as String,
      responsable: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AyudaTypeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.responsable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyudaTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
