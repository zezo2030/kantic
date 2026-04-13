import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {}

class Guest extends AuthState {}

class OtpSent extends AuthState {
  final String phone;

  const OtpSent({required this.phone});

  @override
  List<Object> get props => [phone];
}

class OtpVerified extends AuthState {
  final AuthResponseEntity authResponse;

  const OtpVerified({required this.authResponse});

  @override
  List<Object> get props => [authResponse];
}

class RegisterOtpSent extends AuthState {
  final String phone;

  const RegisterOtpSent({required this.phone});

  @override
  List<Object> get props => [phone];
}

class RegistrationIncomplete extends AuthState {
  final String phone;

  const RegistrationIncomplete({required this.phone});

  @override
  List<Object> get props => [phone];
}

class RegisterSuccess extends AuthState {
  final AuthResponseEntity authResponse;

  const RegisterSuccess({required this.authResponse});

  @override
  List<Object> get props => [authResponse];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class ProfileUpdating extends AuthState {}

class ProfileUpdated extends AuthState {
  final UserEntity user;

  const ProfileUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileUpdateError extends AuthState {
  final String message;

  const ProfileUpdateError({required this.message});

  @override
  List<Object> get props => [message];
}

class LanguageUpdating extends AuthState {}

class LanguageUpdated extends AuthState {
  final String language;

  const LanguageUpdated({required this.language});

  @override
  List<Object> get props => [language];
}

class LanguageUpdateError extends AuthState {
  final String message;

  const LanguageUpdateError({required this.message});

  @override
  List<Object> get props => [message];
}

class AccountDeleting extends AuthState {}

class AccountDeleted extends AuthState {}

class AccountDeleteError extends AuthState {
  final String message;

  const AccountDeleteError({required this.message});

  @override
  List<Object> get props => [message];
}
