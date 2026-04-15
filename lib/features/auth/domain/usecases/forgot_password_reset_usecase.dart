import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordResetUseCase {
  final AuthRepository repository;

  ForgotPasswordResetUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String phone,
    required String otp,
    required String newPassword,
  }) {
    return repository.forgotPasswordReset(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );
  }
}
