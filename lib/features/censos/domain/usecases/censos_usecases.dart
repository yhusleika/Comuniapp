import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/censo.dart';
import '../entities/censo_record.dart';
import '../repositories/censos_repository.dart';

class GetCensos implements UseCase<List<Censo>, NoParams> {
  final CensosRepository repository;
  GetCensos(this.repository);

  @override
  Future<Either<Failure, List<Censo>>> call(NoParams params) async {
    return await repository.getCensos();
  }
}

class AddCenso implements UseCase<void, Censo> {
  final CensosRepository repository;
  AddCenso(this.repository);

  @override
  Future<Either<Failure, void>> call(Censo censo) async {
    return await repository.addCenso(censo);
  }
}

class GetCensoRecords implements UseCase<List<CensoRecord>, String> {
  final CensosRepository repository;
  GetCensoRecords(this.repository);

  @override
  Future<Either<Failure, List<CensoRecord>>> call(String censoId) async {
    return await repository.getCensoRecords(censoId);
  }
}

class AddCensoRecord implements UseCase<void, CensoRecord> {
  final CensosRepository repository;
  AddCensoRecord(this.repository);

  @override
  Future<Either<Failure, void>> call(CensoRecord record) async {
    return await repository.addCensoRecord(record);
  }
}

class UpdateCensoRecord implements UseCase<void, CensoRecord> {
  final CensosRepository repository;
  UpdateCensoRecord(this.repository);

  @override
  Future<Either<Failure, void>> call(CensoRecord record) async {
    return await repository.updateCensoRecord(record);
  }
}

class DeleteCensoRecord implements UseCase<void, String> {
  final CensosRepository repository;
  DeleteCensoRecord(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteCensoRecord(id);
  }
}
