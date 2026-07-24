import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/management_models.dart';

abstract class EventosRepository {
  Future<Either<Failure, List<ManagementItem>>> getEventos();
  Future<Either<Failure, void>> addEvento(ManagementItem item);
  Future<Either<Failure, void>> updateEvento(ManagementItem item);
  Future<Either<Failure, void>> deleteEvento(String id);
  Future<Either<Failure, List<ManagementItem>>> getUnsyncedEventos();
  Future<Either<Failure, void>> markEventoAsSynced(String id);
}
