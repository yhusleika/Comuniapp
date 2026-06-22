import 'package:hive/hive.dart';
import '../models/audit_log_model.dart';
import '../../../../core/services/hive_config.dart';

abstract class AuditoriaLocalDataSource {
  Future<List<AuditLogModel>> getAuditLogs();
  Future<void> cacheAuditLog(AuditLogModel log);
}

class AuditoriaLocalDataSourceImpl implements AuditoriaLocalDataSource {
  @override
  Future<List<AuditLogModel>> getAuditLogs() async {
    final box = await Hive.openBox<AuditLogModel>(HiveConfig.auditoriaBox);
    final logs = box.values.toList();
    logs.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Descending
    return logs;
  }

  @override
  Future<void> cacheAuditLog(AuditLogModel log) async {
    final box = await Hive.openBox<AuditLogModel>(HiveConfig.auditoriaBox);
    await box.put(log.id, log);
  }
}
