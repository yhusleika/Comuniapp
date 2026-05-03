import 'package:equatable/equatable.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';

abstract class CensosState extends Equatable {
  const CensosState();

  @override
  List<Object?> get props => [];
}

class CensosInitial extends CensosState {}

class CensosLoading extends CensosState {}

class CensosLoaded extends CensosState {
  final List<Censo> censos;
  const CensosLoaded(this.censos);

  @override
  List<Object?> get props => [censos];
}

class CensoRecordsLoaded extends CensosState {
  final List<CensoRecord> records;
  const CensoRecordsLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

class CensoOperationSuccess extends CensosState {}

class CensoError extends CensosState {
  final String message;
  const CensoError(this.message);

  @override
  List<Object?> get props => [message];
}
