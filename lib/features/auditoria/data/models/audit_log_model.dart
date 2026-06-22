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

  AuditLogModel({
    required this.id,
    required this.user,
    required this.role,
    required this.action,
    required this.dateTime,
  }) : super(
          id: id,
          user: user,
          role: role,
          action: action,
          dateTime: dateTime,
        );

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      user: entity.user,
      role: entity.role,
      action: entity.action,
      dateTime: entity.dateTime,
    );
  }

  AuditLog toEntity() {
    return AuditLog(
      id: id,
      user: user,
      role: role,
      action: action,
      dateTime: dateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'role': role,
      'action': action,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? '',
      user: json['user'] ?? '',
      role: json['role'] ?? '',
      action: json['action'] ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
    );
  }
}
