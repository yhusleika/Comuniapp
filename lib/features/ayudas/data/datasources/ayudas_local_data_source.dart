import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
import '../models/ayuda_type_model.dart';

abstract class AyudasLocalDataSource {
  Future<List<AyudaTypeModel>> getAyudaTypes();
  Future<void> cacheAyudaType(AyudaTypeModel ayudaType);
  Future<void> updateAyudaType(AyudaTypeModel ayudaType);
  Future<void> deleteAyudaType(String id);
}

class AyudasLocalDataSourceImpl implements AyudasLocalDataSource {
  @override
  Future<List<AyudaTypeModel>> getAyudaTypes() async {
    final box = await Hive.openBox(HiveConfig.ayudasBox);
    return box.values.cast<AyudaTypeModel>().toList();
  }

  @override
  Future<void> cacheAyudaType(AyudaTypeModel ayudaType) async {
    final box = await Hive.openBox(HiveConfig.ayudasBox);
    await box.put(ayudaType.id, ayudaType);
  }

  @override
  Future<void> updateAyudaType(AyudaTypeModel ayudaType) async {
    final box = await Hive.openBox(HiveConfig.ayudasBox);
    await box.put(ayudaType.id, ayudaType);
  }

  @override
  Future<void> deleteAyudaType(String id) async {
    final box = await Hive.openBox(HiveConfig.ayudasBox);
    await box.delete(id);
  }
}
