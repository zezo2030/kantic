// Create Booking UseCase - Domain Layer
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase({required this.repository});

  Future<BookingEntity> call({
    required String branchId,
    required DateTime startTime,
    required int durationHours,
    required int persons,
    String? couponCode,
    List<Map<String, dynamic>>? addOns,
    String? specialRequests,
    String? contactPhone,
  }) async {
    return await repository.createBooking(
      branchId: branchId,
      startTime: startTime,
      durationHours: durationHours,
      persons: persons,
      couponCode: couponCode,
      addOns: addOns,
      specialRequests: specialRequests,
      contactPhone: contactPhone,
    );
  }
}
