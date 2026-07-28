import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../domain/entities/reporte.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_local_data_source.dart';
import '../models/reporte_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  ReportsRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<Reporte>>> getReports() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteData = await mongoDBService.getRecords('reports');
          for (final json in remoteData) {
            final model = ReporteModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheReporte(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote reports: $e');
        }
      }

      final models = await localDataSource.getReports();
      return Right(models.map((m) => m.toEntity()).toList());
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createReporte(Reporte reporte) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = ReporteModel.fromEntity(reporte);
      
      if (isConnected) {
        try {
          apiSynced = await mongoDBService.createRecord('reports', model.toJson());
        } on Exception catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      }
      
      try {
        await localDataSource.cacheReporte(model.copyWith(isSynced: apiSynced));
      } on Exception catch (e) {
        return Left(CacheFailure(e.toString()));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Reporte>>> getUnsyncedReports() async {
    try {
      final models = await localDataSource.getReports();
      return Right(models.where((m) => !m.isSynced).map((m) => m.toEntity()).toList());
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String id) async {
    try {
      final models = await localDataSource.getReports();
      final index = models.indexWhere((m) => m.id == id);
      if (index != -1) {
        await localDataSource.cacheReporte(models[index].copyWith(isSynced: true));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
