import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
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
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = CensoModel.fromEntity(censo);
      
      if (isConnected) {
        apiSynced = await mongoDBService.createRecord('censos', model.toJson());
      }
      
      final cacheModel = CensoModel(
        id: model.id,
        nombre: model.nombre,
        zona: model.zona,
        responsable: model.responsable,
        fecha: model.fecha,
        camposSeleccionados: model.camposSeleccionados,
        isSynced: apiSynced,
      );
      
      await localDataSource.cacheCenso(cacheModel);
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
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = CensoRecordModel.fromEntity(record);
      
      if (isConnected) {
        apiSynced = await mongoDBService.createRecord('censo_records', model.toJson());
      }
      
      final cacheModel = CensoRecordModel(
        id: model.id,
        censoId: model.censoId,
        jefeFamilia: model.jefeFamilia,
        cedula: model.cedula,
        direccion: model.direccion,
        numeroHijos: model.numeroHijos,
        estatus: model.estatus,
        datosDinamicos: model.datosDinamicos,
        isSynced: apiSynced,
        numEncuesta: model.numEncuesta,
      );
      
      await localDataSource.cacheCensoRecord(cacheModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCensoRecord(CensoRecord record) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = CensoRecordModel.fromEntity(record);
      
      if (isConnected) {
        apiSynced = await mongoDBService.updateRecord('censo_records', model.id, model.toJson());
      }
      
      final cacheModel = CensoRecordModel(
        id: model.id,
        censoId: model.censoId,
        jefeFamilia: model.jefeFamilia,
        cedula: model.cedula,
        direccion: model.direccion,
        numeroHijos: model.numeroHijos,
        estatus: model.estatus,
        datosDinamicos: model.datosDinamicos,
        isSynced: apiSynced,
        numEncuesta: model.numEncuesta,
      );
      
      await localDataSource.updateCensoRecord(cacheModel);
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

  @override
  Future<Either<Failure, List<Censo>>> getUnsyncedCensos() async {
    try {
      final censos = await localDataSource.getCensos();
      return Right(censos.where((c) => !c.isSynced).map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markCensoAsSynced(String id) async {
    try {
      final censos = await localDataSource.getCensos();
      final index = censos.indexWhere((c) => c.id == id);
      if (index != -1) {
        final c = censos[index];
        final updated = CensoModel(
          id: c.id,
          nombre: c.nombre,
          zona: c.zona,
          responsable: c.responsable,
          fecha: c.fecha,
          camposSeleccionados: c.camposSeleccionados,
          isSynced: true,
        );
        await localDataSource.cacheCenso(updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CensoRecord>>> getUnsyncedCensoRecords() async {
    try {
      final box = await Hive.openBox(HiveConfig.censoRecordsBox);
      final records = box.values.cast<CensoRecordModel>().toList();
      return Right(records.where((r) => !r.isSynced).map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markCensoRecordAsSynced(String id) async {
    try {
      final box = await Hive.openBox(HiveConfig.censoRecordsBox);
      final record = box.get(id);
      if (record != null) {
        final updated = CensoRecordModel(
          id: record.id,
          censoId: record.censoId,
          jefeFamilia: record.jefeFamilia,
          cedula: record.cedula,
          direccion: record.direccion,
          numeroHijos: record.numeroHijos,
          estatus: record.estatus,
          datosDinamicos: record.datosDinamicos,
          isSynced: true,
          numEncuesta: record.numEncuesta,
        );
        await localDataSource.updateCensoRecord(updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCenso(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;
      
      if (isConnected) {
        try {
          await mongoDBService.deleteRecord('censos', id);
        } catch (e) {
          debugPrint('Error deleting censo from remote: $e');
        }
      } else {
        // Queue the deletion for later sync
        final syncBox = await Hive.openBox(HiveConfig.syncQueueBox);
        final deletedIds = List<String>.from(syncBox.get('deleted_censos', defaultValue: <String>[]) ?? []);
        if (!deletedIds.contains(id)) {
          deletedIds.add(id);
          await syncBox.put('deleted_censos', deletedIds);
        }
      }
      
      // Always remove locally first (offline-first)
      await localDataSource.deleteCenso(id);
      
      // Also remove associated censo records locally
      final recordsBox = await Hive.openBox(HiveConfig.censoRecordsBox);
      final recordKeys = recordsBox.values
          .cast<CensoRecordModel>()
          .where((r) => r.censoId == id)
          .map((r) => r.id)
          .toList();
      for (final key in recordKeys) {
        await recordsBox.delete(key);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getDeletedCensoIds() async {
    try {
      final syncBox = await Hive.openBox(HiveConfig.syncQueueBox);
      final deletedIds = List<String>.from(syncBox.get('deleted_censos', defaultValue: <String>[]) ?? []);
      return Right(deletedIds);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearDeletedCensoId(String id) async {
    try {
      final syncBox = await Hive.openBox(HiveConfig.syncQueueBox);
      final deletedIds = List<String>.from(syncBox.get('deleted_censos', defaultValue: <String>[]) ?? []);
      deletedIds.remove(id);
      await syncBox.put('deleted_censos', deletedIds);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}

