import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/reporte.dart';
import '../../domain/usecases/get_reports.dart';
import '../../domain/usecases/create_report.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audit_logger_service.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetReports getReports;
  final CreateReport createReport;

  ReportsBloc({
    required this.getReports,
    required this.createReport,
  }) : super(ReportsInitial()) {
    on<LoadReports>(_onLoadReports);
    on<CreateReportRequested>(_onCreateReportRequested);
  }

  Future<void> _onLoadReports(LoadReports event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    final result = await getReports(NoParams());
    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (reports) => emit(ReportsLoaded(reports)),
    );
  }

  Future<void> _onCreateReportRequested(CreateReportRequested event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    final result = await createReport(CreateReportParams(reporte: event.reporte));
    result.fold(
      (failure) => emit(ReportsError(failure.message)),
      (_) {
        emit(ReportOperationSuccess());
        sl<AuditLoggerService>().log('Registró el reporte "${event.reporte.titulo}"');
        add(LoadReports());
      },
    );
  }
}
