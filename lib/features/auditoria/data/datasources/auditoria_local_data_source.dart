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
    final box = await Hive.openBox(HiveConfig.auditoriaBox);
    if (box.isEmpty) {
      final now = DateTime.now();
      final defaultLogs = [
        AuditLogModel(
          id: 'aud_1',
          user: 'admin',
          role: 'Administrador',
          action: 'Inicio de sesión en el sistema',
          dateTime: now.subtract(const Duration(minutes: 15)),
          isSynced: true,
        ),
        AuditLogModel(
          id: 'aud_2',
          user: 'juan.perez',
          role: 'Operador',
          action: 'Creación de registro de censo poblacional',
          dateTime: now.subtract(const Duration(hours: 2)),
          isSynced: true,
        ),
        AuditLogModel(
          id: 'aud_3',
          user: 'maria.lopez',
          role: 'Operador',
          action: 'Asignación de ayuda de medicamentos',
          dateTime: now.subtract(const Duration(hours: 5)),
          isSynced: true,
        ),
        AuditLogModel(
          id: 'aud_4',
          user: 'admin',
          role: 'Administrador',
          action: 'Actualización de roles de usuario',
          dateTime: now.subtract(const Duration(days: 1)),
          isSynced: true,
        ),
      ];
      for (var log in defaultLogs) {
        await box.put(log.id, log);
      }
    }
    final logs = box.values.whereType<AuditLogModel>().toList();
    logs.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Descending
    return logs;
  }

  @override
  Future<void> cacheAuditLog(AuditLogModel log) async {
    final box = await Hive.openBox(HiveConfig.auditoriaBox);
    await box.put(log.id, log);
  }
}
