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

  @override
  @HiveField(4)
  final String? nombres;
  @override
  @HiveField(5)
  final String? apellidos;
  @override
  @HiveField(6)
  final String? cedula;
  @override
  @HiveField(7)
  final String? email;
  @override
  @HiveField(8)
  final String? telefono;
  @override
  @HiveField(9)
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.passwordHash,
    this.nombres,
    this.apellidos,
    this.cedula,
    this.email,
    this.telefono,
    this.photoUrl,
  }) : super(
          id: id,
          username: username,
          role: role,
          nombres: nombres,
          apellidos: apellidos,
          cedula: cedula,
          email: email,
          telefono: telefono,
          photoUrl: photoUrl,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      passwordHash: json['passwordHash'],
      nombres: json['nombres'],
      apellidos: json['apellidos'],
      cedula: json['cedula'],
      email: json['email'],
      telefono: json['telefono'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'role': role,
      'passwordHash': passwordHash,
      'nombres': nombres,
      'apellidos': apellidos,
      'cedula': cedula,
      'email': email,
      'telefono': telefono,
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromEntity(User entity, {String? passwordHash}) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      role: entity.role,
      passwordHash: passwordHash,
      nombres: entity.nombres,
      apellidos: entity.apellidos,
      cedula: entity.cedula,
      email: entity.email,
      telefono: entity.telefono,
      photoUrl: entity.photoUrl,
    );
  }
}
