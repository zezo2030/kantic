import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/subscription_purchase_model.dart';
import '../../domain/usecases/get_my_subscriptions_usecase.dart';

abstract class MySubscriptionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MySubscriptionsInitial extends MySubscriptionsState {}

class MySubscriptionsLoading extends MySubscriptionsState {}

class MySubscriptionsLoaded extends MySubscriptionsState {
  final List<SubscriptionPurchaseModel> items;
  final int page;
  final int totalPages;
  final String? statusFilter;

  MySubscriptionsLoaded({
    required this.items,
    required this.page,
    required this.totalPages,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [items, page, totalPages, statusFilter];
}

class MySubscriptionsError extends MySubscriptionsState {
  final String message;

  MySubscriptionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MySubscriptionsCubit extends Cubit<MySubscriptionsState> {
  final GetMySubscriptionsUseCase getMy;

  MySubscriptionsCubit({required this.getMy}) : super(MySubscriptionsLoading());

  Future<void> refresh({String? status}) async {
    await loadPage(1, status: status, append: false);
  }

  Future<void> loadPage(int page, {String? status, bool append = false}) async {
    try {
      final r = await getMy(page: page, limit: 10, status: status);
      if (append && state is MySubscriptionsLoaded) {
        final prev = (state as MySubscriptionsLoaded).items;
        emit(
          MySubscriptionsLoaded(
            items: [...prev, ...r.items],
            page: r.page,
            totalPages: r.totalPages,
            statusFilter: status,
          ),
        );
      } else {
        emit(
          MySubscriptionsLoaded(
            items: r.items,
            page: r.page,
            totalPages: r.totalPages,
            statusFilter: status,
          ),
        );
      }
    } catch (e) {
      emit(MySubscriptionsError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is! MySubscriptionsLoaded) return;
    final s = state as MySubscriptionsLoaded;
    if (s.page >= s.totalPages) return;
    await loadPage(s.page + 1, status: s.statusFilter, append: true);
  }
}
