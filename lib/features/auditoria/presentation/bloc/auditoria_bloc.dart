import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/auditoria_usecases.dart';
import 'auditoria_event.dart';
import 'auditoria_state.dart';

class AuditoriaBloc extends Bloc<AuditoriaEvent, AuditoriaState> {
  final GetAuditLogs getAuditLogs;

  AuditoriaBloc({
    required this.getAuditLogs,
  }) : super(AuditoriaInitial()) {
    on<LoadAuditLogs>(_onLoadAuditLogs);
  }

  Future<void> _onLoadAuditLogs(
      LoadAuditLogs event, Emitter<AuditoriaState> emit) async {
    emit(AuditoriaLoading());
    final result = await getAuditLogs();
    result.fold(
      (failure) => emit(AuditoriaError(failure.message)),
      (logs) => emit(AuditoriaLoaded(logs)),
    );
  }
}
