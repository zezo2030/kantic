import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class UpdateLanguageUseCase {
  final AuthRepository repository;

  UpdateLanguageUseCase({required this.repository});

  Future<Either<Failure, bool>> call(String language) async {
    return await repository.updateLanguage(language);
  }
}
