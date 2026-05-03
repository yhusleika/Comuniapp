import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ayudas_repository.dart';

class DeleteAyudaType implements UseCase<void, String> {
  final AyudasRepository repository;

  DeleteAyudaType(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteAyudaType(params);
  }
}
