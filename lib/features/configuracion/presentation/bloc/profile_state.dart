import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  final bool isEditing;
  final File? tempImage;

  const ProfileLoaded({
    required this.user,
    required this.isEditing,
    this.tempImage,
  });

  ProfileLoaded copyWith({
    User? user,
    bool? isEditing,
    File? tempImage,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      isEditing: isEditing ?? this.isEditing,
      tempImage: tempImage ?? this.tempImage,
    );
  }

  @override
  List<Object?> get props => [user, isEditing, tempImage];
}

class ProfileSuccess extends ProfileState {
  final User user;
  const ProfileSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
