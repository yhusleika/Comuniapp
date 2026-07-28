// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habitante_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitanteModelAdapter extends TypeAdapter<HabitanteModel> {
  @override
  final int typeId = 1;

  @override
  HabitanteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitanteModel(
      id: fields[0] as String,
      cedula: fields[1] as String,
      nombres: fields[2] as String,
      apellidos: fields[3] as String,
      telefono: fields[4] as String,
      sector: fields[5] as String,
      puntoReferencia: fields[6] as String,
      tieneDiscapacidad: fields[7] as bool,
      detallesDiscapacidad: fields[8] as String,
      tieneEnfermedadCronica: fields[9] as bool,
      detallesEnfermedad: fields[10] as String,
      condicionVivienda: fields[11] as String,
      tipoVivienda: fields[12] as String,
      registeredBy: fields[13] as String,
      fechaRegistro: fields[14] as DateTime,
      fechaNacimiento: fields[17] as DateTime?,
      genero: fields[18] as String,
      isSynced: fields[15] as bool,
      ayudaRecibida: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HabitanteModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cedula)
      ..writeByte(2)
      ..write(obj.nombres)
      ..writeByte(3)
      ..write(obj.apellidos)
      ..writeByte(4)
      ..write(obj.telefono)
      ..writeByte(5)
      ..write(obj.sector)
      ..writeByte(6)
      ..write(obj.puntoReferencia)
      ..writeByte(7)
      ..write(obj.tieneDiscapacidad)
      ..writeByte(8)
      ..write(obj.detallesDiscapacidad)
      ..writeByte(9)
      ..write(obj.tieneEnfermedadCronica)
      ..writeByte(10)
      ..write(obj.detallesEnfermedad)
      ..writeByte(11)
      ..write(obj.condicionVivienda)
      ..writeByte(12)
      ..write(obj.tipoVivienda)
      ..writeByte(13)
      ..write(obj.registeredBy)
      ..writeByte(14)
      ..write(obj.fechaRegistro)
      ..writeByte(15)
      ..write(obj.isSynced)
      ..writeByte(16)
      ..write(obj.ayudaRecibida)
      ..writeByte(17)
      ..write(obj.fechaNacimiento)
      ..writeByte(18)
      ..write(obj.genero);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitanteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
