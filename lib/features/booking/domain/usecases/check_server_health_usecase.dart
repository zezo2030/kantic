// Check Server Health Use Case - Domain Layer
import '../repositories/booking_repository.dart';

class CheckServerHealthUseCase {
  final BookingRepository repository;

  CheckServerHealthUseCase({required this.repository});

  Future<bool> call() async {
    return await repository.checkServerHealth();
  }
}
