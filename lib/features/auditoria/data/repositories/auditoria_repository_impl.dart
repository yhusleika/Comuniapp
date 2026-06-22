import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/auditoria_repository.dart';
import '../datasources/auditoria_local_data_source.dart';
import '../models/audit_log_model.dart';

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  final AuditoriaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  AuditoriaRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<AuditLog>>> getAuditLogs() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteData = await mongoDBService.getRecords('auditoria');
          for (final json in remoteData) {
            final model = AuditLogModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheAuditLog(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote audit logs: $e');
        }
      }

      final models = await localDataSource.getAuditLogs();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAuditLog(AuditLog log) async {
    try {
      final model = AuditLogModel.fromEntity(log);
      
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.createRecord('auditoria', model.toJson());
      }
      
      await localDataSource.cacheAuditLog(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
