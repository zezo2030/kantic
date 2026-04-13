import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String refreshToken,
  }) async {
    return await repository.refreshToken(
      refreshToken: refreshToken,
    );
  }
}

