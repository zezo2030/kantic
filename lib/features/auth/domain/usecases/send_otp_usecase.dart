import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String phone,
    String language = 'ar',
  }) async {
    return await repository.sendOtp(
      phone: phone,
      language: language,
    );
  }
}
