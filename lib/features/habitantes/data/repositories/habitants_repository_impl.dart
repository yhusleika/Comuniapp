import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../domain/entities/habitante.dart';
import '../../domain/repositories/habitants_repository.dart';
import '../datasources/habitants_local_data_source.dart';
import '../models/habitante_model.dart';

class HabitantsRepositoryImpl implements HabitantsRepository {
  final HabitantsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  HabitantsRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<Habitante>>> getHabitants(String query) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteData = await mongoDBService.getRecords('habitants');
          for (final json in remoteData) {
            final model = HabitanteModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheHabitante(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote habitants: $e');
        }
      }

      final models = await localDataSource.getHabitants();
      final habitants = models.map((m) => m.toEntity()).toList();
      
      if (query.isNotEmpty) {
        final filtered = habitants.where((h) {
          return h.nombres.toLowerCase().contains(query.toLowerCase()) ||
              h.apellidos.toLowerCase().contains(query.toLowerCase()) ||
              h.cedula.contains(query);
        }).toList();
        return Right(filtered);
      }
      return Right(habitants);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addHabitante(Habitante habitante) async {
    try {
      if (habitante.cedula.isNotEmpty) {
        try {
          final existing = await localDataSource.getHabitants();
          if (existing.any((h) => h.cedula == habitante.cedula && h.id != habitante.id)) {
            return Left(CacheFailure('Ya existe un habitante registrado con la cédula ${habitante.cedula}'));
          }
        } on Exception catch (e) {
          return Left(CacheFailure(e.toString()));
        }
      }

      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = HabitanteModel.fromEntity(habitante);
      
      if (isConnected) {
        try {
          apiSynced = await mongoDBService.createRecord('habitants', model.toJson());
        } on Exception catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      }
      
      try {
        await localDataSource.cacheHabitante(model.copyWith(isSynced: apiSynced));
      } on Exception catch (e) {
        return Left(CacheFailure(e.toString()));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateHabitante(Habitante habitante) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = HabitanteModel.fromEntity(habitante);
      
      if (isConnected) {
        try {
          apiSynced = await mongoDBService.updateRecord('habitants', model.id, model.toJson());
        } on Exception catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      }
      
      try {
        await localDataSource.updateHabitante(model.copyWith(isSynced: apiSynced));
      } on Exception catch (e) {
        return Left(CacheFailure(e.toString()));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabitante(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await mongoDBService.deleteRecord('habitants', id);
        } on Exception catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      }
      try {
        await localDataSource.deleteHabitante(id);
      } on Exception catch (e) {
        return Left(CacheFailure(e.toString()));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Habitante>>> getUnsyncedHabitants() async {
    try {
      final models = await localDataSource.getHabitants();
      return Right(models.where((m) => !m.isSynced).map((m) => m.toEntity()).toList());
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String id) async {
    try {
      final models = await localDataSource.getHabitants();
      final index = models.indexWhere((m) => m.id == id);
      if (index != -1) {
        await localDataSource.updateHabitante(models[index].copyWith(isSynced: true));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncHabitants() async {
    return const Right(null);
  }
}
