import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../datasources/censos_local_data_source.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';
import '../models/censo_model.dart';
import '../models/censo_record_model.dart';
import '../../domain/repositories/censos_repository.dart';

class CensosRepositoryImpl implements CensosRepository {
  final CensosLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  CensosRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<Censo>>> getCensos() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteData = await mongoDBService.getRecords('censos');
          for (final json in remoteData) {
            final model = CensoModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheCenso(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote censos: $e');
        }
      }

      final models = await localDataSource.getCensos();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCenso(Censo censo) async {
    try {
      final model = CensoModel.fromEntity(censo);
      
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.createRecord('censos', model.toJson());
      }
      
      await localDataSource.cacheCenso(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CensoRecord>>> getCensoRecords(
      String censoId) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          // Fetch remote records for this censo
          final remoteData = await mongoDBService.getRecords('censo_records?censoId=$censoId');
          for (final json in remoteData) {
            final model = CensoRecordModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheCensoRecord(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote censo records: $e');
        }
      }

      final models = await localDataSource.getCensoRecords(censoId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCensoRecord(CensoRecord record) async {
    try {
      final model = CensoRecordModel.fromEntity(record);
      
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.createRecord('censo_records', model.toJson());
      }
      
      await localDataSource.cacheCensoRecord(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCensoRecord(CensoRecord record) async {
    try {
      final model = CensoRecordModel.fromEntity(record);
      
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.updateRecord('censo_records', model.id, model.toJson());
      }
      
      await localDataSource.updateCensoRecord(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCensoRecord(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.deleteRecord('censo_records', id);
      }
      
      await localDataSource.deleteCensoRecord(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
