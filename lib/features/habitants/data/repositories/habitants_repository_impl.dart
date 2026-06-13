import 'package:dartz/dartz.dart';
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
      final habitants = await localDataSource.getHabitants();
      // Simple filtering
      if (query.isNotEmpty) {
        final filtered = habitants.where((h) {
          return h.nombres.toLowerCase().contains(query.toLowerCase()) ||
              h.apellidos.toLowerCase().contains(query.toLowerCase()) ||
              h.cedula.contains(query);
        }).toList();
        return Right(filtered);
      }
      return Right(habitants);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addHabitante(Habitante habitante) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = HabitanteModel.fromEntity(habitante);
      
      if (isConnected) {
        apiSynced = await mongoDBService.createRecord('habitants', model.toJson());
      }
      
      final cacheModel = HabitanteModel(
        id: model.id,
        cedula: model.cedula,
        nombres: model.nombres,
        apellidos: model.apellidos,
        telefono: model.telefono,
        sector: model.sector,
        ayudaRecibida: model.ayudaRecibida,
        puntoReferencia: model.puntoReferencia,
        tieneDiscapacidad: model.tieneDiscapacidad,
        tieneEnfermedadCronica: model.tieneEnfermedadCronica,
        condicionVivienda: model.condicionVivienda,
        tipoVivienda: model.tipoVivienda,
        registeredBy: model.registeredBy,
        fechaRegistro: model.fechaRegistro,
        detallesDiscapacidad: model.detallesDiscapacidad,
        detallesEnfermedad: model.detallesEnfermedad,
        isSynced: apiSynced,
      );
      
      await localDataSource.cacheHabitante(cacheModel);
      return const Right(null);
    } catch (e) {
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
        apiSynced = await mongoDBService.updateRecord('habitants', model.id, model.toJson());
      }
      
      final cacheModel = HabitanteModel(
        id: model.id,
        cedula: model.cedula,
        nombres: model.nombres,
        apellidos: model.apellidos,
        telefono: model.telefono,
        sector: model.sector,
        ayudaRecibida: model.ayudaRecibida,
        puntoReferencia: model.puntoReferencia,
        tieneDiscapacidad: model.tieneDiscapacidad,
        tieneEnfermedadCronica: model.tieneEnfermedadCronica,
        condicionVivienda: model.condicionVivienda,
        tipoVivienda: model.tipoVivienda,
        registeredBy: model.registeredBy,
        fechaRegistro: model.fechaRegistro,
        detallesDiscapacidad: model.detallesDiscapacidad,
        detallesEnfermedad: model.detallesEnfermedad,
        isSynced: apiSynced,
      );
      
      await localDataSource.updateHabitante(cacheModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabitante(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await mongoDBService.deleteRecord('habitants', id);
      }
      await localDataSource.deleteHabitante(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Habitante>>> getUnsyncedHabitants() async {
    try {
      final habitants = await localDataSource.getHabitants();
      return Right(habitants.where((element) => !element.isSynced).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String id) async {
    try {
      final habitants = await localDataSource.getHabitants();
      final index = habitants.indexWhere((h) => h.id == id);
      if (index != -1) {
        final habitante = habitants[index];
        final updated = HabitanteModel(
          id: habitante.id,
          cedula: habitante.cedula,
          nombres: habitante.nombres,
          apellidos: habitante.apellidos,
          telefono: habitante.telefono,
          sector: habitante.sector,
          ayudaRecibida: habitante.ayudaRecibida,
          puntoReferencia: habitante.puntoReferencia,
          tieneDiscapacidad: habitante.tieneDiscapacidad,
          tieneEnfermedadCronica: habitante.tieneEnfermedadCronica,
          condicionVivienda: habitante.condicionVivienda,
          tipoVivienda: habitante.tipoVivienda,
          registeredBy: habitante.registeredBy,
          fechaRegistro: habitante.fechaRegistro,
          detallesDiscapacidad: habitante.detallesDiscapacidad,
          detallesEnfermedad: habitante.detallesEnfermedad,
          isSynced: true,
        );
        await localDataSource.updateHabitante(updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncHabitants() async {
    return const Right(null);
  }
}
