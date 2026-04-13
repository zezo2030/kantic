// Get Quote UseCase - Domain Layer
import '../entities/quote_entity.dart';
import '../repositories/booking_repository.dart';

class GetQuoteUseCase {
  final BookingRepository repository;

  GetQuoteUseCase({required this.repository});

  Future<QuoteEntity> call({
    required String branchId,
    required DateTime startTime,
    required int durationHours,
    required int persons,
    List<Map<String, dynamic>>? addOns,
    String? couponCode,
  }) async {
    return await repository.getQuote(
      branchId: branchId,
      startTime: startTime,
      durationHours: durationHours,
      persons: persons,
      addOns: addOns,
      couponCode: couponCode,
    );
  }
}
