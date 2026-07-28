part of 'habitants_bloc.dart';

abstract class HabitantsState extends Equatable {
  const HabitantsState();
  
  @override
  List<Object> get props => [];
}

class HabitantsInitial extends HabitantsState {}

class HabitantsLoading extends HabitantsState {}

class HabitantsLoaded extends HabitantsState {
  final List<Habitante> habitants;
  const HabitantsLoaded(this.habitants);

  @override
  List<Object> get props => [habitants];
}

class HabitantsError extends HabitantsState {
  final String message;
  const HabitantsError(this.message);

  @override
  List<Object> get props => [message];
}

class HabitanteOperationSuccess extends HabitantsState {}
