import 'package:equatable/equatable.dart';
import '../../domain/entities/audit_log.dart';

abstract class AuditoriaState extends Equatable {
  const AuditoriaState();
  
  @override
  List<Object> get props => [];
}

class AuditoriaInitial extends AuditoriaState {}

class AuditoriaLoading extends AuditoriaState {}

class AuditoriaLoaded extends AuditoriaState {
  final List<AuditLog> logs;

  const AuditoriaLoaded(this.logs);

  @override
  List<Object> get props => [logs];
}

class AuditoriaError extends AuditoriaState {
  final String message;

  const AuditoriaError(this.message);

  @override
  List<Object> get props => [message];
}
