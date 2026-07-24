// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evento_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventoModelAdapter extends TypeAdapter<EventoModel> {
  @override
  final int typeId = 8;

  @override
  EventoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventoModel(
      id: fields[0] as String,
      name: fields[1] as String,
      date: fields[2] as DateTime,
      description: fields[3] as String,
      responsible: fields[4] as String,
      category: fields[5] as String,
      progress: fields[6] as double,
      status: fields[7] as String,
      attendeeNames: (fields[8] as List).cast<String>(),
      photos: (fields[9] as List).cast<String>(),
      avancesRaw: (fields[11] as List)
          .map((dynamic e) => (e as Map).cast<dynamic, dynamic>())
          .toList(),
      isSynced: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EventoModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.responsible)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.progress)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.attendeeNames)
      ..writeByte(9)
      ..write(obj.photos)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.avancesRaw);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
