import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
import '../models/censo_model.dart';
import '../models/censo_record_model.dart';

abstract class CensosLocalDataSource {
  Future<List<CensoModel>> getCensos();
  Future<void> cacheCenso(CensoModel censo);

  Future<List<CensoRecordModel>> getCensoRecords(String censoId);
  Future<void> cacheCensoRecord(CensoRecordModel record);
  Future<void> updateCensoRecord(CensoRecordModel record);
  Future<void> deleteCensoRecord(String id);
}

class CensosLocalDataSourceImpl implements CensosLocalDataSource {
  @override
  Future<List<CensoModel>> getCensos() async {
    final box = await Hive.openBox(HiveConfig.censosBox);
    return box.values.cast<CensoModel>().toList();
  }

  @override
  Future<void> cacheCenso(CensoModel censo) async {
    final box = await Hive.openBox(HiveConfig.censosBox);
    await box.put(censo.id, censo);
  }

  @override
  Future<List<CensoRecordModel>> getCensoRecords(String censoId) async {
    final box = await Hive.openBox(HiveConfig.censoRecordsBox);
    return box.values
        .cast<CensoRecordModel>()
        .where((r) => r.censoId == censoId)
        .toList();
  }

  @override
  Future<void> cacheCensoRecord(CensoRecordModel record) async {
    final box = await Hive.openBox(HiveConfig.censoRecordsBox);
    await box.put(record.id, record);
  }

  @override
  Future<void> updateCensoRecord(CensoRecordModel record) async {
    final box = await Hive.openBox(HiveConfig.censoRecordsBox);
    await box.put(record.id, record);
  }

  @override
  Future<void> deleteCensoRecord(String id) async {
    final box = await Hive.openBox(HiveConfig.censoRecordsBox);
    await box.delete(id);
  }
}
