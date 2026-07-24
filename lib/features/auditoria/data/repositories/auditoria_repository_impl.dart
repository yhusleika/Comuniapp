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
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = AuditLogModel.fromEntity(log);
      
      if (isConnected) {
        apiSynced = await mongoDBService.createRecord('auditoria', model.toJson());
      }
      
      final cacheModel = AuditLogModel(
        id: model.id,
        user: model.user,
        role: model.role,
        action: model.action,
        dateTime: model.dateTime,
        isSynced: apiSynced,
      );
      
      await localDataSource.cacheAuditLog(cacheModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AuditLog>>> getUnsyncedAuditLogs() async {
    try {
      final logs = await localDataSource.getAuditLogs();
      return Right(logs.where((l) => !l.isSynced).map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAuditLogAsSynced(String id) async {
    try {
      final logs = await localDataSource.getAuditLogs();
      final index = logs.indexWhere((l) => l.id == id);
      if (index != -1) {
        final l = logs[index];
        final updated = AuditLogModel(
          id: l.id,
          user: l.user,
          role: l.role,
          action: l.action,
          dateTime: l.dateTime,
          isSynced: true,
        );
        await localDataSource.cacheAuditLog(updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
