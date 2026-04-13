import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../domain/usecases/get_branch_subscription_plans_usecase.dart';

abstract class SubscriptionPlansState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionPlansInitial extends SubscriptionPlansState {}

class SubscriptionPlansLoading extends SubscriptionPlansState {}

class SubscriptionPlansLoaded extends SubscriptionPlansState {
  final List<SubscriptionPlanModel> plans;

  SubscriptionPlansLoaded(this.plans);

  @override
  List<Object?> get props => [plans];
}

class SubscriptionPlansError extends SubscriptionPlansState {
  final String message;

  SubscriptionPlansError(this.message);

  @override
  List<Object?> get props => [message];
}

class SubscriptionPlansCubit extends Cubit<SubscriptionPlansState> {
  final GetBranchSubscriptionPlansUseCase getPlans;

  SubscriptionPlansCubit({required this.getPlans})
      : super(SubscriptionPlansInitial());

  Future<void> load(String branchId) async {
    emit(SubscriptionPlansLoading());
    try {
      final plans = await getPlans(branchId);
      emit(SubscriptionPlansLoaded(plans));
    } catch (e) {
      emit(SubscriptionPlansError(e.toString()));
    }
  }
}
