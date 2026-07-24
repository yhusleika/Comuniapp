import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/censo.dart';
import '../entities/censo_record.dart';

abstract class CensosRepository {
  Future<Either<Failure, List<Censo>>> getCensos();
  Future<Either<Failure, void>> addCenso(Censo censo);
  Future<Either<Failure, void>> deleteCenso(String id);

  Future<Either<Failure, List<CensoRecord>>> getCensoRecords(String censoId);
  Future<Either<Failure, void>> addCensoRecord(CensoRecord record);
  Future<Either<Failure, void>> updateCensoRecord(CensoRecord record);
  Future<Either<Failure, void>> deleteCensoRecord(String id);
  Future<Either<Failure, List<Censo>>> getUnsyncedCensos();
  Future<Either<Failure, void>> markCensoAsSynced(String id);
  Future<Either<Failure, List<CensoRecord>>> getUnsyncedCensoRecords();
  Future<Either<Failure, void>> markCensoRecordAsSynced(String id);
  Future<Either<Failure, List<String>>> getDeletedCensoIds();
  Future<Either<Failure, void>> clearDeletedCensoId(String id);
}
