import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_remote_datasource.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final LoyaltyRemoteDataSource remote;

  LoyaltyRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, LoyaltyInfoEntity>> getLoyaltyInfo() async {
    try {
      final model = await remote.getLoyaltyInfo();
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, RedeemTicketResult>> redeemTicket({
    required String branchId,
  }) async {
    try {
      final response = await remote.redeemTicket(branchId: branchId);

      final booking = response['booking'] as Map<String, dynamic>?;
      final tickets = booking?['tickets'] as List<dynamic>?;
      final firstTicket = tickets?.isNotEmpty == true
          ? tickets!.first as Map<String, dynamic>?
          : null;

      return Right(
        RedeemTicketResult(
          bookingId: booking?['id'] as String? ?? response['id'] as String? ?? '',
          qrCode: firstTicket?['qrCode'] as String?,
          ticketId: firstTicket?['id'] as String?,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
