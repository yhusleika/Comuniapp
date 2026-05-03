import 'package:equatable/equatable.dart';
import '../../domain/entities/ayuda_type.dart';

abstract class AyudasState extends Equatable {
  const AyudasState();

  @override
  List<Object> get props => [];
}

class AyudasInitial extends AyudasState {}

class AyudasLoading extends AyudasState {}

class AyudasLoaded extends AyudasState {
  final List<AyudaType> ayudaTypes;
  const AyudasLoaded(this.ayudaTypes);

  @override
  List<Object> get props => [ayudaTypes];
}

class AyudaOperationSuccess extends AyudasState {}

class AyudasError extends AyudasState {
  final String message;
  const AyudasError(this.message);

  @override
  List<Object> get props => [message];
}
