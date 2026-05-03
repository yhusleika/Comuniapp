import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ayuda_type.dart';

abstract class AyudasRepository {
  Future<Either<Failure, List<AyudaType>>> getAyudaTypes();
  Future<Either<Failure, void>> addAyudaType(AyudaType ayudaType);
  Future<Either<Failure, void>> updateAyudaType(AyudaType ayudaType);
  Future<Either<Failure, void>> deleteAyudaType(String id);
}
