import 'package:hive/hive.dart';
import '../../domain/entities/audit_log.dart';

part 'audit_log_model.g.dart';

@HiveType(typeId: 7)
class AuditLogModel extends AuditLog {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String user;

  @HiveField(2)
  @override
  final String role;

  @HiveField(3)
  @override
  final String action;

  @HiveField(4)
  @override
  final DateTime dateTime;

  @HiveField(5, defaultValue: false)
  @override
  final bool isSynced;

  AuditLogModel({
    required this.id,
    required this.user,
    required this.role,
    required this.action,
    required this.dateTime,
    this.isSynced = false,
  }) : super(
          id: id,
          user: user,
          role: role,
          action: action,
          dateTime: dateTime,
          isSynced: isSynced,
        );

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      user: entity.user,
      role: entity.role,
      action: entity.action,
      dateTime: entity.dateTime,
      isSynced: entity.isSynced,
    );
  }

  AuditLog toEntity() {
    return AuditLog(
      id: id,
      user: user,
      role: role,
      action: action,
      dateTime: dateTime,
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'role': role,
      'action': action,
      'dateTime': dateTime.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] != null && json['id'].toString().isNotEmpty)
          ? json['id'].toString()
          : (json['_id']?.toString() ?? ''),
      user: json['user'] ?? json['usuario'] ?? 'Sistema',
      role: json['role'] ?? json['rol'] ?? 'Administrador',
      action: json['action'] ?? json['accion'] ?? 'Acción del sistema',
      dateTime: DateTime.tryParse(json['dateTime'] ?? json['fecha'] ?? '') ?? DateTime.now(),
      isSynced: true,
    );
  }
}
