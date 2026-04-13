import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String phone,
    required String otp,
  }) async {
    return await repository.verifyOtp(
      phone: phone,
      otp: otp,
    );
  }
}
