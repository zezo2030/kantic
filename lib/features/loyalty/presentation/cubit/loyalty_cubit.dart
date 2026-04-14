import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_loyalty_info_usecase.dart';
import '../../domain/usecases/redeem_ticket_usecase.dart';
import 'loyalty_state.dart';

class LoyaltyCubit extends Cubit<LoyaltyState> {
  final GetLoyaltyInfoUseCase getLoyaltyInfoUseCase;
  final RedeemTicketUseCase redeemTicketUseCase;

  LoyaltyCubit({
    required this.getLoyaltyInfoUseCase,
    required this.redeemTicketUseCase,
  }) : super(LoyaltyInitial());

  Future<void> loadLoyaltyInfo() async {
    emit(LoyaltyLoading());
    final result = await getLoyaltyInfoUseCase();
    result.fold(
      (failure) => emit(LoyaltyError(failure.message)),
      (info) => emit(LoyaltyLoaded(info)),
    );
  }

  Future<void> redeemTicket({required String branchId}) async {
    final currentInfo = _currentInfo;
    if (currentInfo == null) return;

    emit(LoyaltyRedeemLoading(currentInfo));

    final result = await redeemTicketUseCase(branchId: branchId);

    await result.fold(
      (failure) async {
        emit(LoyaltyRedeemError(info: currentInfo, message: failure.message));
      },
      (ticket) async {
        // Refresh loyalty info after successful redemption
        final refreshResult = await getLoyaltyInfoUseCase();
        refreshResult.fold(
          (failure) => emit(LoyaltyRedeemSuccess(info: currentInfo, ticket: ticket)),
          (updatedInfo) => emit(LoyaltyRedeemSuccess(info: updatedInfo, ticket: ticket)),
        );
      },
    );
  }

  dynamic get _currentInfo {
    final s = state;
    if (s is LoyaltyLoaded) return s.info;
    if (s is LoyaltyRedeemError) return s.info;
    return null;
  }
}
