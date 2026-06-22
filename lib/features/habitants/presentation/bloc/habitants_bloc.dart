import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/habitante.dart';
import '../../domain/usecases/get_habitants.dart';
import '../../domain/usecases/add_habitante.dart';
import '../../domain/usecases/update_habitante.dart';
import '../../domain/usecases/delete_habitante.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audit_logger_service.dart';

part 'habitants_event.dart';
part 'habitants_state.dart';

class HabitantsBloc extends Bloc<HabitantsEvent, HabitantsState> {
  final GetHabitants getHabitants;
  final AddHabitante addHabitante;
  final UpdateHabitante updateHabitante;
  final DeleteHabitante deleteHabitante;

  HabitantsBloc({
    required this.getHabitants,
    required this.addHabitante,
    required this.updateHabitante,
    required this.deleteHabitante,
  }) : super(HabitantsInitial()) {
    on<LoadHabitants>(_onLoadHabitants);
    on<CreateHabitante>(_onCreateHabitante);
    on<UpdateHabitanteEvent>(_onUpdateHabitante);
    on<DeleteHabitanteEvent>(_onDeleteHabitante);
  }

  Future<void> _onLoadHabitants(
      LoadHabitants event, Emitter<HabitantsState> emit) async {
    emit(HabitantsLoading());
    final result = await getHabitants(GetHabitantsParams(query: event.query));
    result.fold(
      (failure) => emit(HabitantsError(failure.message)),
      (habitants) => emit(HabitantsLoaded(habitants)),
    );
  }

  Future<void> _onCreateHabitante(
      CreateHabitante event, Emitter<HabitantsState> emit) async {
    final result =
        await addHabitante(AddHabitanteParams(habitante: event.habitante));
    result.fold(
      (failure) => emit(HabitantsError(failure.message)),
      (_) {
        emit(HabitanteOperationSuccess());
        sl<AuditLoggerService>().log('Registró al habitante "${event.habitante.nombres} ${event.habitante.apellidos}"');
        add(const LoadHabitants());
      },
    );
  }

  Future<void> _onUpdateHabitante(
      UpdateHabitanteEvent event, Emitter<HabitantsState> emit) async {
    final result = await updateHabitante(
        UpdateHabitanteParams(habitante: event.habitante));
    result.fold(
      (failure) => emit(HabitantsError(failure.message)),
      (_) {
        emit(HabitanteOperationSuccess());
        sl<AuditLoggerService>().log('Modificó al habitante "${event.habitante.nombres} ${event.habitante.apellidos}"');
        add(const LoadHabitants());
      },
    );
  }

  Future<void> _onDeleteHabitante(
      DeleteHabitanteEvent event, Emitter<HabitantsState> emit) async {
    final result = await deleteHabitante(DeleteHabitanteParams(id: event.id));
    result.fold(
      (failure) => emit(HabitantsError(failure.message)),
      (_) {
        emit(HabitanteOperationSuccess());
        sl<AuditLoggerService>().log('Eliminó un habitante con ID "${event.id}"');
        add(const LoadHabitants());
      },
    );
  }
}
