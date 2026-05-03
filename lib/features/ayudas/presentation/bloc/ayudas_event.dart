import 'package:equatable/equatable.dart';
import '../../domain/entities/ayuda_type.dart';

abstract class AyudasEvent extends Equatable {
  const AyudasEvent();

  @override
  List<Object> get props => [];
}

class LoadAyudaTypes extends AyudasEvent {}

class CreateAyudaType extends AyudasEvent {
  final AyudaType ayudaType;
  const CreateAyudaType(this.ayudaType);

  @override
  List<Object> get props => [ayudaType];
}

class UpdateAyudaTypeEvent extends AyudasEvent {
  final AyudaType ayudaType;
  const UpdateAyudaTypeEvent(this.ayudaType);

  @override
  List<Object> get props => [ayudaType];
}

class DeleteAyudaTypeEvent extends AyudasEvent {
  final String id;
  const DeleteAyudaTypeEvent(this.id);

  @override
  List<Object> get props => [id];
}
