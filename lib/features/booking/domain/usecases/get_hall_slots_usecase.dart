// Get Branch Slots Use Case - Domain Layer
import '../entities/hall_slots_entity.dart';
import '../repositories/booking_repository.dart';

class GetBranchSlotsUseCase {
  final BookingRepository repository;

  GetBranchSlotsUseCase({required this.repository});

  Future<BranchSlotsEntity> call({
    required String branchId,
    required DateTime date,
    int durationHours = 1,
    int? slotMinutes,
    int? persons,
  }) {
    return repository.getBranchSlots(
      branchId: branchId,
      date: date,
      durationHours: durationHours,
      slotMinutes: slotMinutes,
      persons: persons,
    );
  }
}

