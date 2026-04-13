import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../data/models/update_profile_dto.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call(
    UpdateProfileDto updateProfileDto,
  ) async {
    return await repository.updateProfile(updateProfileDto);
  }
}
