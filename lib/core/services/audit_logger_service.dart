import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auditoria/domain/entities/audit_log.dart';
import '../../features/auditoria/domain/usecases/auditoria_usecases.dart';

import '../../core/services/hive_config.dart';
import '../../features/auth/data/models/user_model.dart';

class AuditLoggerService {
  final AuthBloc authBloc;
  final AddAuditLog addAuditLog;
  final _uuid = const Uuid();

  AuditLoggerService({
    required this.authBloc,
    required this.addAuditLog,
  });

  /// Formatea el rol técnico ('admin', 'operador', 'visor') a un rol formal ('Administrador', 'Operador', 'Visor')
  static String formatRole(String rawRole) {
    if (rawRole.isEmpty) return 'Operador';
    final lower = rawRole.trim().toLowerCase();
    if (lower.contains('admin')) return 'Administrador';
    if (lower.contains('visor')) return 'Visor';
    if (lower.contains('vocero')) return 'Vocero';
    if (lower.contains('operador')) return 'Operador';
    return '${rawRole[0].toUpperCase()}${rawRole.substring(1)}';
  }

  /// Limpia textos de acción para evitar mostrar hashes o UUIDs crudos
  static String sanitizeAction(String action) {
    if (action.isEmpty) return action;

    // Eliminar GUIDs/UUIDs crudos y patrones con "con ID ..." o "ID ..."
    String clean = action
        .replaceAll(RegExp(r'con ID "[a-f0-9\-]{10,}"', caseSensitive: false), '')
        .replaceAll(RegExp(r'ID "[a-f0-9\-]{10,}"', caseSensitive: false), '')
        .replaceAll(RegExp(r'[a-f0-9]{8}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{12}', caseSensitive: false), '')
        .trim();

    return clean;
  }

  /// Registra una acción de auditoría con el usuario responsable real y su rol asignado
  Future<void> log(String action) async {
    String user = '';
    String role = '';

    final state = authBloc.state;
    if (state is AuthAuthenticated) {
      user = state.user.username;
      role = state.user.role;
    }

    if (user.isEmpty) {
      try {
        const userBoxName = HiveConfig.userBox;
        final box = Hive.isBoxOpen(userBoxName) ? Hive.box(userBoxName) : await Hive.openBox(userBoxName);
        final cached = box.get('current_user');
        if (cached is UserModel) {
          user = cached.username;
          role = cached.role;
        } else if (cached != null) {
          user = (cached['username'] ?? cached['user'] ?? '').toString();
          role = (cached['role'] ?? '').toString();
        }
      } catch (_) {}
    }

    if (user.isEmpty) {
      user = 'usuario';
    }

    final finalRole = formatRole(role);

    final newLog = AuditLog(
      id: _uuid.v4(),
      user: user,
      role: finalRole,
      action: sanitizeAction(action),
      dateTime: DateTime.now(),
    );

    await addAuditLog(newLog);
  }
}
