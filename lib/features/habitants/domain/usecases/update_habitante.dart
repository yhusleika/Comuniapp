import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/habitante.dart';
import '../repositories/habitants_repository.dart';

class UpdateHabitante implements UseCase<void, UpdateHabitanteParams> {
  final HabitantsRepository repository;

  UpdateHabitante(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateHabitanteParams params) async {
    return await repository.updateHabitante(params.habitante);
  }
}

class UpdateHabitanteParams extends Equatable {
  final Habitante habitante;

  const UpdateHabitanteParams({required this.habitante});

  @override
  List<Object> get props => [habitante];
}
