import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remote;

  WalletRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, WalletEntity>> getWalletBalance() async {
    try {
      final wallet = await remote.getWalletBalance();
      return Right(wallet.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final transactions = await remote.getTransactions(
        type: type,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RedeemPointsResult>> redeemPoints({
    required int points,
  }) async {
    try {
      final response = await remote.redeemPoints(points: points);

      int toInt(dynamic v, [int fallback = 0]) {
        if (v == null) return fallback;
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v) ?? fallback;
        return fallback;
      }

      double toDouble(dynamic v, [double fallback = 0.0]) {
        if (v == null) return fallback;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? fallback;
        return fallback;
      }

      // Backend returns { redeemed: points, credit: value }
      final result = RedeemPointsResult(
        redeemed: toInt(response['redeemed'], points),
        credit: toDouble(response['credit']),
      );

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
