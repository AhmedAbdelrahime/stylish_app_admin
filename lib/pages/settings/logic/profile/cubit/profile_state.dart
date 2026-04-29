import 'package:equatable/equatable.dart';
import 'package:hungry/pages/settings/data/user_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdated extends ProfileState {
  final UserModel user;

  const ProfileUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
