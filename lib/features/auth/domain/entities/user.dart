import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String role; // 'admin' or 'vocero'
  final String? nombres;
  final String? apellidos;
  final String? cedula;
  final String? email;
  final String? telefono;
  final String? photoUrl;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.nombres,
    this.apellidos,
    this.cedula,
    this.email,
    this.telefono,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, username, role, nombres, apellidos, cedula, email, telefono, photoUrl];
}
