import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<ToggleEditProfileMode>(_onToggleEditProfileMode);
    on<SelectProfileImage>(_onSelectProfileImage);
    on<SaveProfileEvent>(_onSaveProfileEvent);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await repository.getUserProfile(event.username);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (user) => emit(ProfileLoaded(user: user, isEditing: false)),
    );
  }

  Future<void> _onToggleEditProfileMode(ToggleEditProfileMode event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(isEditing: event.isEditing));
    }
  }

  Future<void> _onSelectProfileImage(SelectProfileImage event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(tempImage: event.imageFile));
    }
  }

  Future<void> _onSaveProfileEvent(SaveProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    
    final result = await repository.updateProfile(
      user: event.user,
      imageFile: event.imageFile,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (updatedUser) {
        emit(ProfileSuccess(updatedUser));
        emit(ProfileLoaded(user: updatedUser, isEditing: false));
      },
    );
  }
}
