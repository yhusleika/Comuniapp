part of 'reports_bloc.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  
  @override
  List<Object> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<Reporte> reports;
  const ReportsLoaded(this.reports);

  @override
  List<Object> get props => [reports];
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);

  @override
  List<Object> get props => [message];
}

class ReportOperationSuccess extends ReportsState {}
