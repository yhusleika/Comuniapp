import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/ayudas_local_data_source.dart';
import '../../domain/entities/ayuda_type.dart';
import '../models/ayuda_type_model.dart';
import '../../domain/repositories/ayudas_repository.dart';

class AyudasRepositoryImpl implements AyudasRepository {
  final AyudasLocalDataSource localDataSource;

  AyudasRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<AyudaType>>> getAyudaTypes() async {
    try {
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
      await localDataSource.updateAyudaType(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAyudaType(String id) async {
    try {
      await localDataSource.deleteAyudaType(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
