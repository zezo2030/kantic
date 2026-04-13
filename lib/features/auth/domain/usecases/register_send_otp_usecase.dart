import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterSendOtpUseCase {
  final AuthRepository repository;

  RegisterSendOtpUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String phone,
    String language = 'ar',
  }) async {
    return await repository.registerSendOtp(
      phone: phone,
      language: language,
    );
  }
}
