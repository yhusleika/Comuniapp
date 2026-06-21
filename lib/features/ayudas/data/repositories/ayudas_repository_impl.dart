import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../datasources/ayudas_local_data_source.dart';
import '../../domain/entities/ayuda_type.dart';
import '../models/ayuda_type_model.dart';
import '../../domain/repositories/ayudas_repository.dart';

class AyudasRepositoryImpl implements AyudasRepository {
  final AyudasLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  AyudasRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<AyudaType>>> getAyudaTypes() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteData = await mongoDBService.getRecords('ayudas');
          for (final json in remoteData) {
            final model = AyudaTypeModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheAyudaType(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote ayudas: $e');
        }
      }

      final models = await localDataSource.getAyudaTypes();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAyudaType(AyudaType ayudaType) async {
    try {
      final model = AyudaTypeModel.fromEntity(ayudaType);
      
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.createRecord('ayudas', model.toJson());
      }
      
      await localDataSource.cacheAyudaType(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAyudaType(AyudaType ayudaType) async {
    try {
      final model = AyudaTypeModel.fromEntity(ayudaType);
      
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.updateRecord('ayudas', model.id, model.toJson());
      }
      
      await localDataSource.updateAyudaType(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAyudaType(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.deleteRecord('ayudas', id);
      }
      
      await localDataSource.deleteAyudaType(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
