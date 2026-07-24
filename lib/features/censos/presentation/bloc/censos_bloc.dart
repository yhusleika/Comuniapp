import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../bloc/censos_event.dart';
import '../bloc/censos_state.dart';
import '../../domain/usecases/censos_usecases.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audit_logger_service.dart';

class CensosBloc extends Bloc<CensosEvent, CensosState> {
  final GetCensos getCensos;
  final AddCenso addCenso;
  final DeleteCenso deleteCensoUseCase;
  final GetCensoRecords getCensoRecords;
  final AddCensoRecord addCensoRecord;
  final UpdateCensoRecord updateCensoRecord;
  final DeleteCensoRecord deleteCensoRecord;

  CensosBloc({
    required this.getCensos,
    required this.addCenso,
    required this.deleteCensoUseCase,
    required this.getCensoRecords,
    required this.addCensoRecord,
    required this.updateCensoRecord,
    required this.deleteCensoRecord,
  }) : super(CensosInitial()) {
    on<LoadCensos>(_onLoadCensos);
    on<CreateCenso>(_onCreateCenso);
    on<DeleteCensoEvent>(_onDeleteCenso);
    on<LoadCensoRecords>(_onLoadCensoRecords);
    on<AddCensoRecordEvent>(_onAddCensoRecord);
    on<UpdateCensoRecordEvent>(_onUpdateCensoRecord);
    on<DeleteCensoRecordEvent>(_onDeleteCensoRecord);
  }

  Future<void> _onLoadCensos(
      LoadCensos event, Emitter<CensosState> emit) async {
    emit(CensosLoading());
    final result = await getCensos(NoParams());
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (list) => emit(CensosLoaded(list)),
    );
  }

  Future<void> _onCreateCenso(
      CreateCenso event, Emitter<CensosState> emit) async {
    final result = await addCenso(event.censo);
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (_) {
        emit(CensoOperationSuccess());
        sl<AuditLoggerService>().log('Creó el censo "${event.censo.nombre}"');
        add(LoadCensos());
      },
    );
  }

  Future<void> _onLoadCensoRecords(
      LoadCensoRecords event, Emitter<CensosState> emit) async {
    emit(CensosLoading());
    final result = await getCensoRecords(event.censoId);
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (records) => emit(CensoRecordsLoaded(records)),
    );
  }

  Future<void> _onAddCensoRecord(
      AddCensoRecordEvent event, Emitter<CensosState> emit) async {
    final result = await addCensoRecord(event.record);
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (_) {
        emit(CensoOperationSuccess());
        sl<AuditLoggerService>().log('Agregó un nuevo registro al censo');
        add(LoadCensoRecords(event.record.censoId));
      },
    );
  }

  Future<void> _onUpdateCensoRecord(
      UpdateCensoRecordEvent event, Emitter<CensosState> emit) async {
    final result = await updateCensoRecord(event.record);
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (_) {
        emit(CensoOperationSuccess());
        sl<AuditLoggerService>().log('Actualizó un registro del censo');
        add(LoadCensoRecords(event.record.censoId));
      },
    );
  }

  Future<void> _onDeleteCenso(
      DeleteCensoEvent event, Emitter<CensosState> emit) async {
    final result = await deleteCensoUseCase(event.id);
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (_) {
        emit(CensoOperationSuccess());
        sl<AuditLoggerService>().log('Eliminó el censo "${event.nombre}"');
        add(LoadCensos());
      },
    );
  }

  Future<void> _onDeleteCensoRecord(
      DeleteCensoRecordEvent event, Emitter<CensosState> emit) async {
    final result = await deleteCensoRecord(event.id);
    result.fold(
      (failure) => emit(CensoError(failure.message)),
      (_) {
        emit(CensoOperationSuccess());
        sl<AuditLoggerService>().log('Eliminó un registro de censo');
      },
    );
  }
}
