import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message});
}

// Authentication Failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.statusCode});
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({required super.message});
}

class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure({required super.message});
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

// Storage Failures
class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}

// Unknown Failure
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
