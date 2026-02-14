part of 'habitants_bloc.dart';

abstract class HabitantsEvent extends Equatable {
  const HabitantsEvent();

  @override
  List<Object> get props => [];
}

class LoadHabitants extends HabitantsEvent {
  final String query;
  const LoadHabitants({this.query = ''});

  @override
  List<Object> get props => [query];
}

class CreateHabitante extends HabitantsEvent {
  final Habitante habitante;
  const CreateHabitante(this.habitante);

  @override
  List<Object> get props => [habitante];
}

class UpdateHabitanteEvent extends HabitantsEvent {
  final Habitante habitante;
  const UpdateHabitanteEvent(this.habitante);

  @override
  List<Object> get props => [habitante];
}

class DeleteHabitanteEvent extends HabitantsEvent {
  final String id;
  const DeleteHabitanteEvent(this.id);

  @override
  List<Object> get props => [id];
}

class SyncHabitantsRequested extends HabitantsEvent {}
