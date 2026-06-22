import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_ayuda_types.dart';
import '../../domain/usecases/add_ayuda_type.dart';
import '../../domain/usecases/update_ayuda_type.dart';
import '../../domain/usecases/delete_ayuda_type.dart';
import 'ayudas_event.dart';
import 'ayudas_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audit_logger_service.dart';

class AyudasBloc extends Bloc<AyudasEvent, AyudasState> {
  final GetAyudaTypes getAyudaTypes;
  final AddAyudaType addAyudaType;
  final UpdateAyudaType updateAyudaType;
  final DeleteAyudaType deleteAyudaType;

  AyudasBloc({
    required this.getAyudaTypes,
    required this.addAyudaType,
    required this.updateAyudaType,
    required this.deleteAyudaType,
  }) : super(AyudasInitial()) {
    on<LoadAyudaTypes>(_onLoadAyudaTypes);
    on<CreateAyudaType>(_onCreateAyudaType);
    on<UpdateAyudaTypeEvent>(_onUpdateAyudaType);
    on<DeleteAyudaTypeEvent>(_onDeleteAyudaType);
  }

  Future<void> _onLoadAyudaTypes(
      LoadAyudaTypes event, Emitter<AyudasState> emit) async {
    emit(AyudasLoading());
    final result = await getAyudaTypes(NoParams());
    result.fold(
      (failure) => emit(AyudasError(failure.message)),
      (types) => emit(AyudasLoaded(types)),
    );
  }

  Future<void> _onCreateAyudaType(
      CreateAyudaType event, Emitter<AyudasState> emit) async {
    final result = await addAyudaType(event.ayudaType);
    result.fold(
      (failure) => emit(AyudasError(failure.message)),
      (_) {
        emit(AyudaOperationSuccess());
        sl<AuditLoggerService>().log('Creó la ayuda social "${event.ayudaType.nombre}"');
        add(LoadAyudaTypes());
      },
    );
  }

  Future<void> _onUpdateAyudaType(
      UpdateAyudaTypeEvent event, Emitter<AyudasState> emit) async {
    final result = await updateAyudaType(event.ayudaType);
    result.fold(
      (failure) => emit(AyudasError(failure.message)),
      (_) {
        emit(AyudaOperationSuccess());
        sl<AuditLoggerService>().log('Modificó la ayuda social "${event.ayudaType.nombre}"');
        add(LoadAyudaTypes());
      },
    );
  }

  Future<void> _onDeleteAyudaType(
      DeleteAyudaTypeEvent event, Emitter<AyudasState> emit) async {
    final result = await deleteAyudaType(event.id);
    result.fold(
      (failure) => emit(AyudasError(failure.message)),
      (_) {
        emit(AyudaOperationSuccess());
        sl<AuditLoggerService>().log('Eliminó una ayuda social con ID "${event.id}"');
        add(LoadAyudaTypes());
      },
    );
  }
}
