import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterVerifyOtpUseCase {
  final AuthRepository repository;

  RegisterVerifyOtpUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String phone,
    required String otp,
  }) async {
    return await repository.registerVerifyOtp(
      phone: phone,
      otp: otp,
    );
  }
}
