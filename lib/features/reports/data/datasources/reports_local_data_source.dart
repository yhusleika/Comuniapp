import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
import '../models/reporte_model.dart';

abstract class ReportsLocalDataSource {
  Future<List<ReporteModel>> getReports();
  Future<void> cacheReporte(ReporteModel reporte);
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  @override
  Future<List<ReporteModel>> getReports() async {
    final box = await Hive.openBox(HiveConfig.reportsBox);
    return box.values.cast<ReporteModel>().toList();
  }

  @override
  Future<void> cacheReporte(ReporteModel reporte) async {
    final box = await Hive.openBox(HiveConfig.reportsBox);
    await box.put(reporte.id, reporte);
  }
}
