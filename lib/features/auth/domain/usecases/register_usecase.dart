import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String name,
    required String email,
    required String password,
    String? phone,
    String language = 'ar',
  }) async {
    return await repository.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      language: language,
    );
  }
}





















