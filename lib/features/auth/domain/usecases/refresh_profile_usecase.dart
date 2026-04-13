import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RefreshProfileUseCase {
  final AuthRepository repository;

  RefreshProfileUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.refreshProfile();
  }
}
