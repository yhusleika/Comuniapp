import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ayuda_type.dart';
import '../repositories/ayudas_repository.dart';

class UpdateAyudaType implements UseCase<void, AyudaType> {
  final AyudasRepository repository;

  UpdateAyudaType(this.repository);

  @override
  Future<Either<Failure, void>> call(AyudaType params) async {
    return await repository.updateAyudaType(params);
  }
}
