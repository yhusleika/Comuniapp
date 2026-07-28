import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/habitants_repository.dart';

class DeleteHabitante implements UseCase<void, DeleteHabitanteParams> {
  final HabitantsRepository repository;

  DeleteHabitante(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteHabitanteParams params) async {
    return await repository.deleteHabitante(params.id);
  }
}

class DeleteHabitanteParams extends Equatable {
  final String id;

  const DeleteHabitanteParams({required this.id});

  @override
  List<Object> get props => [id];
}
