import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/redeem_points_usecase.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final GetWalletUseCase getWalletUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final RedeemPointsUseCase redeemPointsUseCase;

  WalletCubit({
    required this.getWalletUseCase,
    required this.getTransactionsUseCase,
    required this.redeemPointsUseCase,
  }) : super(WalletInitial());

  Future<void> loadWallet() async {
    emit(WalletLoading());
    final result = await getWalletUseCase();
    result.fold(
      (failure) => emit(WalletError(failure.message)),
      (wallet) => emit(WalletLoaded(wallet: wallet)),
    );
  }

  Future<void> loadWalletWithTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
  }) async {
    await loadWallet();
    await loadTransactions(type: type, status: status);
  }

  Future<void> loadTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
  }) async {
    if (state is WalletLoaded) {
      final currentState = state as WalletLoaded;
      if (page == 1) {
        emit(
          WalletLoaded(
            wallet: currentState.wallet,
            transactions: [],
            isLoadingTransactions: true,
          ),
        );
      }

      final result = await getTransactionsUseCase(
        type: type,
        status: status,
        page: page,
        pageSize: 20,
      );

      result.fold((failure) => emit(WalletError(failure.message)), (
        transactions,
      ) {
        if (state is WalletLoaded) {
          final currentState = state as WalletLoaded;
          final allTransactions = page == 1
              ? transactions
              : [...currentState.transactions, ...transactions];
          emit(
            WalletLoaded(
              wallet: currentState.wallet,
              transactions: allTransactions,
              hasMoreTransactions: transactions.length == 20,
            ),
          );
        }
      });
    }
  }

  Future<void> redeemPoints({required int points}) async {
    if (points <= 0) {
      emit(WalletError('عدد النقاط غير صحيح'));
      return;
    }

    WalletLoaded? currentLoaded;
    if (state is WalletLoaded) currentLoaded = state as WalletLoaded;

    emit(
      WalletRedeemLoading(
        wallet: currentLoaded?.wallet,
        transactions: currentLoaded?.transactions ?? const [],
      ),
    );

    final redeemResult = await redeemPointsUseCase(points: points);

    await redeemResult.fold(
      (failure) async {
        emit(
          WalletRedeemFailed(
            wallet: currentLoaded?.wallet,
            transactions: currentLoaded?.transactions ?? const [],
            error: failure.message,
          ),
        );
      },
      (RedeemPointsResult result) async {
        // Refresh wallet + transactions after redeem
        final walletRes = await getWalletUseCase();
        final txRes = await getTransactionsUseCase(page: 1, pageSize: 20);

        walletRes.fold((failure) => emit(WalletError(failure.message)), (
          wallet,
        ) {
          txRes.fold((failure) => emit(WalletError(failure.message)), (txs) {
            emit(
              WalletRedeemSuccess(
                wallet: wallet,
                transactions: txs,
                redeemedPoints: result.redeemed,
                creditedAmount: result.credit,
              ),
            );
            emit(
              WalletLoaded(
                wallet: wallet,
                transactions: txs,
                hasMoreTransactions: txs.length == 20,
              ),
            );
          });
        });
      },
    );
  }
}
