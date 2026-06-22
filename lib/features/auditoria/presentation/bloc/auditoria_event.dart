import 'package:equatable/equatable.dart';

abstract class AuditoriaEvent extends Equatable {
  const AuditoriaEvent();

  @override
  List<Object> get props => [];
}

class LoadAuditLogs extends AuditoriaEvent {
  const LoadAuditLogs();
}
