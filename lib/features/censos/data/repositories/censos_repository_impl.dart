import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/censos_local_data_source.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';
import '../models/censo_model.dart';
import '../models/censo_record_model.dart';
import '../../domain/repositories/censos_repository.dart';

class CensosRepositoryImpl implements CensosRepository {
  final CensosLocalDataSource localDataSource;

  CensosRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Censo>>> getCensos() async {
    try {
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
      await localDataSource.updateCensoRecord(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCensoRecord(String id) async {
    try {
      await localDataSource.deleteCensoRecord(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
