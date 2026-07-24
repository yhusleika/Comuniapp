import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log.dart';

abstract class AuditoriaRepository {
  Future<Either<Failure, List<AuditLog>>> getAuditLogs();
  Future<Either<Failure, void>> addAuditLog(AuditLog log);
  Future<Either<Failure, List<AuditLog>>> getUnsyncedAuditLogs();
  Future<Either<Failure, void>> markAuditLogAsSynced(String id);
}
