import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_subscription_purchase_usecase.dart';
import '../../domain/usecases/get_subscription_quote_usecase.dart';

abstract class SubscriptionPurchaseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionPurchaseInitial extends SubscriptionPurchaseState {}

class SubscriptionPurchaseLoading extends SubscriptionPurchaseState {}

class SubscriptionPurchaseQuoteReady extends SubscriptionPurchaseState {
  final Map<String, dynamic> quote;

  SubscriptionPurchaseQuoteReady(this.quote);

  @override
  List<Object?> get props => [quote];
}

class SubscriptionPurchaseCreated extends SubscriptionPurchaseState {
  final Map<String, dynamic> result;

  SubscriptionPurchaseCreated(this.result);

  @override
  List<Object?> get props => [result];
}

class SubscriptionPurchaseError extends SubscriptionPurchaseState {
  final String message;

  SubscriptionPurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}

class SubscriptionPurchaseCubit extends Cubit<SubscriptionPurchaseState> {
  final GetSubscriptionQuoteUseCase quoteUseCase;
  final CreateSubscriptionPurchaseUseCase createUseCase;

  SubscriptionPurchaseCubit({
    required this.quoteUseCase,
    required this.createUseCase,
  }) : super(SubscriptionPurchaseInitial());

  Future<void> fetchQuote(String planId) async {
    emit(SubscriptionPurchaseLoading());
    try {
      final q = await quoteUseCase(planId);
      emit(SubscriptionPurchaseQuoteReady(q));
    } catch (e) {
      emit(SubscriptionPurchaseError(e.toString()));
    }
  }

  Future<void> submitPurchase({
    required String planId,
    required bool acceptedTerms,
  }) async {
    emit(SubscriptionPurchaseLoading());
    try {
      final r = await createUseCase(
        subscriptionPlanId: planId,
        acceptedTerms: acceptedTerms,
      );
      emit(SubscriptionPurchaseCreated(r));
    } catch (e) {
      emit(SubscriptionPurchaseError(e.toString()));
    }
  }
}
