import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class CompleteRegistrationUseCase {
  final AuthRepository repository;

  CompleteRegistrationUseCase(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String phone,
    required String name,
    required String password,
    String language = 'ar',
  }) async {
    return await repository.completeRegistration(
      phone: phone,
      name: name,
      password: password,
      language: language,
    );
  }
}


















