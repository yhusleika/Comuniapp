part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadReports extends ReportsEvent {}

class CreateReportRequested extends ReportsEvent {
  final Reporte reporte;
  const CreateReportRequested(this.reporte);

  @override
  List<Object> get props => [reporte];
}
