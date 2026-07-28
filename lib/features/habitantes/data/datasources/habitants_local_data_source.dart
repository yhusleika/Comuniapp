import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
import '../models/habitante_model.dart';

abstract class HabitantsLocalDataSource {
  Future<List<HabitanteModel>> getHabitants();
  Future<void> cacheHabitante(HabitanteModel habitante);
  Future<void> updateHabitante(HabitanteModel habitante);
  Future<void> deleteHabitante(String id);
}

class HabitantsLocalDataSourceImpl implements HabitantsLocalDataSource {
  @override
  Future<List<HabitanteModel>> getHabitants() async {
    final box = await Hive.openBox(HiveConfig.habitantsBox);
    return box.values.cast<HabitanteModel>().toList();
  }

  @override
  Future<void> cacheHabitante(HabitanteModel habitante) async {
    final box = await Hive.openBox(HiveConfig.habitantsBox);
    await box.put(habitante.id, habitante);
  }

  @override
  Future<void> updateHabitante(HabitanteModel habitante) async {
    final box = await Hive.openBox(HiveConfig.habitantsBox);
    await box.put(habitante.id, habitante);
  }

  @override
  Future<void> deleteHabitante(String id) async {
    final box = await Hive.openBox(HiveConfig.habitantsBox);
    await box.delete(id);
  }
}
