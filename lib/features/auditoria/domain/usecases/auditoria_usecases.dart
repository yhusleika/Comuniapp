import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log.dart';
import '../repositories/auditoria_repository.dart';

class GetAuditLogs {
  final AuditoriaRepository repository;

  GetAuditLogs(this.repository);

  Future<Either<Failure, List<AuditLog>>> call() {
    return repository.getAuditLogs();
  }
}

class AddAuditLog {
  final AuditoriaRepository repository;

  AddAuditLog(this.repository);

  Future<Either<Failure, void>> call(AuditLog log) {
    return repository.addAuditLog(log);
  }
}
