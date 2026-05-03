import 'package:equatable/equatable.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';

abstract class CensosEvent extends Equatable {
  const CensosEvent();

  @override
  List<Object?> get props => [];
}

class LoadCensos extends CensosEvent {}

class CreateCenso extends CensosEvent {
  final Censo censo;
  const CreateCenso(this.censo);

  @override
  List<Object?> get props => [censo];
}

class LoadCensoRecords extends CensosEvent {
  final String censoId;
  const LoadCensoRecords(this.censoId);

  @override
  List<Object?> get props => [censoId];
}

class AddCensoRecordEvent extends CensosEvent {
  final CensoRecord record;
  const AddCensoRecordEvent(this.record);

  @override
  List<Object?> get props => [record];
}

class UpdateCensoRecordEvent extends CensosEvent {
  final CensoRecord record;
  const UpdateCensoRecordEvent(this.record);

  @override
  List<Object?> get props => [record];
}

class DeleteCensoRecordEvent extends CensosEvent {
  final String id;
  const DeleteCensoRecordEvent(this.id);

  @override
  List<Object?> get props => [id];
}
