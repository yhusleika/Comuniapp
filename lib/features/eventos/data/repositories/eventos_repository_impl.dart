import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../domain/models/management_models.dart';
import '../../domain/repositories/eventos_repository.dart';
import '../datasources/eventos_local_data_source.dart';
import '../models/evento_model.dart';

class EventosRepositoryImpl implements EventosRepository {
  final EventosLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  EventosRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<ManagementItem>>> getEventos() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteData = await mongoDBService.getRecords('eventos');
          for (final json in remoteData) {
            final model = EventoModel.fromJson(Map<String, dynamic>.from(json));
            await localDataSource.cacheEvento(model);
          }
        } catch (e) {
          debugPrint('Error fetching remote eventos: $e');
        }
      }

      final models = await localDataSource.getEventos();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addEvento(ManagementItem item) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = EventoModel.fromEntity(item);
      
      if (isConnected) {
        apiSynced = await mongoDBService.createRecord('eventos', model.toJson());
      }
      
      final cacheModel = EventoModel(
        id: model.id,
        name: model.name,
        date: model.date,
        description: model.description,
        responsible: model.responsible,
        category: model.category,
        progress: model.progress,
        status: model.status,
        attendeeNames: model.attendeeNames,
        photos: model.photos,
        avancesRaw: model.avancesRaw,
        isSynced: apiSynced,
      );
      
      await localDataSource.cacheEvento(cacheModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEvento(ManagementItem item) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = EventoModel.fromEntity(item);
      
      if (isConnected) {
        apiSynced = await mongoDBService.updateRecord('eventos', model.id, model.toJson());
      }
      
      final cacheModel = EventoModel(
        id: model.id,
        name: model.name,
        date: model.date,
        description: model.description,
        responsible: model.responsible,
        category: model.category,
        progress: model.progress,
        status: model.status,
        attendeeNames: model.attendeeNames,
        photos: model.photos,
        avancesRaw: model.avancesRaw,
        isSynced: apiSynced,
      );
      
      await localDataSource.updateEvento(cacheModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvento(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.deleteRecord('eventos', id);
      }
      
      await localDataSource.deleteEvento(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ManagementItem>>> getUnsyncedEventos() async {
    try {
      final items = await localDataSource.getEventos();
      return Right(items.where((i) => !i.isSynced).map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markEventoAsSynced(String id) async {
    try {
      final items = await localDataSource.getEventos();
      final index = items.indexWhere((i) => i.id == id);
      if (index != -1) {
        final i = items[index];
        final updated = EventoModel(
          id: i.id,
          name: i.name,
          date: i.date,
          description: i.description,
          responsible: i.responsible,
          category: i.category,
          progress: i.progress,
          status: i.status,
          attendeeNames: i.attendeeNames,
          photos: i.photos,
          avancesRaw: i.avancesRaw,
          isSynced: true,
        );
        await localDataSource.cacheEvento(updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
