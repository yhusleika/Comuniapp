class AuditLog {
  final String id;
  final String user;
  final String role;
  final String action;
  final DateTime dateTime;

  AuditLog({
    required this.id,
    required this.user,
    required this.role,
    required this.action,
    required this.dateTime,
  });
}
