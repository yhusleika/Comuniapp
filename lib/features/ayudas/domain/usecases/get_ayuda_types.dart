import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ayuda_type.dart';
import '../repositories/ayudas_repository.dart';

class GetAyudaTypes implements UseCase<List<AyudaType>, NoParams> {
  final AyudasRepository repository;

  GetAyudaTypes(this.repository);

  @override
  Future<Either<Failure, List<AyudaType>>> call(NoParams params) async {
    return await repository.getAyudaTypes();
  }
}
