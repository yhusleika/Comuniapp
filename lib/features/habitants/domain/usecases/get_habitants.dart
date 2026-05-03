import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/habitante.dart';
import '../repositories/habitants_repository.dart';
import 'package:equatable/equatable.dart';

class GetHabitants implements UseCase<List<Habitante>, GetHabitantsParams> {
  final HabitantsRepository repository;

  GetHabitants(this.repository);

  @override
  Future<Either<Failure, List<Habitante>>> call(GetHabitantsParams params) async {
    return await repository.getHabitants(params.query);
  }
}

class GetHabitantsParams extends Equatable {
  final String query;

  const GetHabitantsParams({this.query = ''});

  @override
  List<Object> get props => [query];
}
