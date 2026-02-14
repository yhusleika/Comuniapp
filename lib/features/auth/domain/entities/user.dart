import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String role; // 'admin' or 'vocero'

  const User({required this.id, required this.username, required this.role});

  @override
  List<Object> get props => [id, username, role];
}
