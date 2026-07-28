import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/habitante.dart';
import '../repositories/habitants_repository.dart';

class AddHabitante implements UseCase<void, AddHabitanteParams> {
  final HabitantsRepository repository;

  AddHabitante(this.repository);

  @override
  Future<Either<Failure, void>> call(AddHabitanteParams params) async {
    return await repository.addHabitante(params.habitante);
  }
}

class AddHabitanteParams extends Equatable {
  final Habitante habitante;

  const AddHabitanteParams({required this.habitante});

  @override
  List<Object> get props => [habitante];
}
