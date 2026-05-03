import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/habitants/data/models/habitante_model.dart';
import '../../features/reports/data/models/reporte_model.dart';
import '../../features/ayudas/data/models/ayuda_type_model.dart';
import '../../features/censos/data/models/censo_model.dart';
import '../../features/censos/data/models/censo_record_model.dart';

class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // WIPE CENSOS BOXES FOR DEVELOPMENT SCHEMA MIGRATION
    try {
      await Hive.deleteBoxFromDisk(censosBox);
      await Hive.deleteBoxFromDisk(censoRecordsBox);
    } catch (_) {}

    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(HabitanteModelAdapter());
    Hive.registerAdapter(ReporteModelAdapter());
    Hive.registerAdapter(AyudaTypeModelAdapter());
    Hive.registerAdapter(CensoModelAdapter());
    Hive.registerAdapter(CensoRecordModelAdapter());
  }

  static const String habitantsBox = 'habitants';
  static const String reportsBox = 'reports';
  static const String syncQueueBox = 'sync_queue';
  static const String userBox = 'user_session';
  static const String ayudasBox = 'ayudas_types';
  static const String censosBox = 'censos';
  static const String censoRecordsBox = 'censo_records';
}
