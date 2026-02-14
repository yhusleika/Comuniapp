import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/censo.dart';
import '../entities/censo_record.dart';

abstract class CensosRepository {
  Future<Either<Failure, List<Censo>>> getCensos();
  Future<Either<Failure, void>> addCenso(Censo censo);

  Future<Either<Failure, List<CensoRecord>>> getCensoRecords(String censoId);
  Future<Either<Failure, void>> addCensoRecord(CensoRecord record);
  Future<Either<Failure, void>> updateCensoRecord(CensoRecord record);
  Future<Either<Failure, void>> deleteCensoRecord(String id);
}
