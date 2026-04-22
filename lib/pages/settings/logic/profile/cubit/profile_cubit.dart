import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService profileService;

  ProfileCubit(this.profileService) : super(ProfileInitial());

  UserModel? currentUser;

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final user = await profileService.getProfile();
      if (user != null) {
        currentUser = user;
        emit(ProfileLoaded(user));
      } else {
        emit(const ProfileError("User not found"));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    emit(ProfileUpdating());
    try {
      await profileService.updateProfile(updatedUser);
      currentUser = updatedUser;
      emit(ProfileUpdated(updatedUser));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
