import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String username;
  const LoadProfile(this.username);

  @override
  List<Object?> get props => [username];
}

class ToggleEditProfileMode extends ProfileEvent {
  final bool isEditing;
  const ToggleEditProfileMode(this.isEditing);

  @override
  List<Object?> get props => [isEditing];
}

class SelectProfileImage extends ProfileEvent {
  final File imageFile;
  const SelectProfileImage(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class SaveProfileEvent extends ProfileEvent {
  final User user;
  final File? imageFile;
  final String? newPassword;

  const SaveProfileEvent({
    required this.user,
    this.imageFile,
    this.newPassword,
  });

  @override
  List<Object?> get props => [user, imageFile, newPassword];
}
