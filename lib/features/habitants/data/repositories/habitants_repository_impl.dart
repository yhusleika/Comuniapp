import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/habitante.dart';
import '../../domain/repositories/habitants_repository.dart';
import '../datasources/habitants_local_data_source.dart';
import '../models/habitante_model.dart';

class HabitantsRepositoryImpl implements HabitantsRepository {
  final HabitantsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HabitantsRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
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
      final model = HabitanteModel.fromEntity(habitante);
      await localDataSource.cacheHabitante(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateHabitante(Habitante habitante) async {
    try {
      final model = HabitanteModel.fromEntity(habitante);
      await localDataSource.updateHabitante(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabitante(String id) async {
    try {
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
