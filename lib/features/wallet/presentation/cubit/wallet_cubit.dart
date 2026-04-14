import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/recharge_wallet_usecase.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final GetWalletUseCase getWalletUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final RechargeWalletUseCase rechargeWalletUseCase;

  WalletCubit({
    required this.getWalletUseCase,
    required this.getTransactionsUseCase,
    required this.rechargeWalletUseCase,
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
          final current = state as WalletLoaded;
          final all = page == 1
              ? transactions
              : [...current.transactions, ...transactions];
          emit(
            WalletLoaded(
              wallet: current.wallet,
              transactions: all,
              hasMoreTransactions: transactions.length == 20,
            ),
          );
        }
      });
    }
  }

  Future<void> rechargeWallet({
    required double amount,
  }) async {
    final currentLoaded = state is WalletLoaded ? state as WalletLoaded : null;

    emit(
      WalletRechargeLoading(
        wallet: currentLoaded?.wallet,
        transactions: currentLoaded?.transactions ?? const [],
      ),
    );

    final result = await rechargeWalletUseCase(amount: amount);

    result.fold(
      (failure) {
        emit(
          WalletRechargeFailed(
            wallet: currentLoaded?.wallet,
            transactions: currentLoaded?.transactions ?? const [],
            error: failure.message,
          ),
        );
      },
      (rechargeResult) {
        emit(
          WalletRechargeSuccess(
            wallet: currentLoaded?.wallet,
            transactions: currentLoaded?.transactions ?? const [],
            redirectUrl: rechargeResult.redirectUrl,
            paymentId: rechargeResult.paymentId,
            amount: amount,
          ),
        );
        if (currentLoaded != null) {
          emit(
            WalletLoaded(
              wallet: currentLoaded.wallet,
              transactions: currentLoaded.transactions,
              hasMoreTransactions: currentLoaded.hasMoreTransactions,
            ),
          );
        }
      },
    );
  }

  Future<bool> confirmRechargePayment({
    required String paymentId,
    required String moyasarPaymentId,
  }) async {
    final result = await rechargeWalletUseCase.confirmPayment(
      paymentId: paymentId,
      moyasarPaymentId: moyasarPaymentId,
    );

    bool confirmed = false;
    result.fold(
      (failure) {
        emit(WalletError(failure.message));
      },
      (ok) {
        confirmed = ok;
      },
    );

    if (confirmed) {
      await loadWalletWithTransactions();
    }

    return confirmed;
  }
}
