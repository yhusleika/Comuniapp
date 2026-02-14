// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'censo_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CensoRecordModelAdapter extends TypeAdapter<CensoRecordModel> {
  @override
  final int typeId = 6;

  @override
  CensoRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CensoRecordModel(
      id: fields[0] as String,
      censoId: fields[1] as String,
      jefeFamilia: fields[2] as String,
      cedula: fields[3] as String,
      direccion: fields[4] as String,
      numeroHijos: fields[5] as int,
      estatus: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CensoRecordModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.censoId)
      ..writeByte(2)
      ..write(obj.jefeFamilia)
      ..writeByte(3)
      ..write(obj.cedula)
      ..writeByte(4)
      ..write(obj.direccion)
      ..writeByte(5)
      ..write(obj.numeroHijos)
      ..writeByte(6)
      ..write(obj.estatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CensoRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
