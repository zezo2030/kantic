import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordSendOtpUseCase {
  final AuthRepository repository;

  ForgotPasswordSendOtpUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String phone,
    String language = 'ar',
  }) {
    return repository.forgotPasswordSendOtp(phone: phone, language: language);
  }
}
