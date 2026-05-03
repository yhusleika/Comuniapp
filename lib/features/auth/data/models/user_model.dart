import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends User {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String username;
  @override
  @HiveField(2)
  final String role;
  @HiveField(3)
  final String? passwordHash;

  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.passwordHash,
  }) : super(id: id, username: username, role: role);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'role': role,
    };
  }
}
