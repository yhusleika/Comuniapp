import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/habitante.dart';

abstract class HabitantsRepository {
  Future<Either<Failure, List<Habitante>>> getHabitants(String query);
  Future<Either<Failure, void>> addHabitante(Habitante habitante);
  Future<Either<Failure, void>> updateHabitante(Habitante habitante);
  Future<Either<Failure, List<Habitante>>> getUnsyncedHabitants();
  Future<Either<Failure, void>> markAsSynced(String id);
  Future<Either<Failure, void>> syncHabitants();
  Future<Either<Failure, void>> deleteHabitante(String id);
}
