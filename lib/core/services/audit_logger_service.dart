import 'package:uuid/uuid.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auditoria/domain/entities/audit_log.dart';
import '../../features/auditoria/domain/usecases/auditoria_usecases.dart';

class AuditLoggerService {
  final AuthBloc authBloc;
  final AddAuditLog addAuditLog;
  final _uuid = const Uuid();

  AuditLoggerService({
    required this.authBloc,
    required this.addAuditLog,
  });

  /// Registra una acción de auditoría
  Future<void> log(String action) async {
    final state = authBloc.state;
    String user = 'Sistema';
    String role = 'Sistema';

    if (state is AuthAuthenticated) {
      user = state.user.username;
      role = state.user.role;
    }

    final newLog = AuditLog(
      id: _uuid.v4(),
      user: user,
      role: role,
      action: action,
      dateTime: DateTime.now(),
    );

    await addAuditLog(newLog);
  }
}
