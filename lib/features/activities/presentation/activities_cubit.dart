import 'package:flutter_bloc/flutter_bloc.dart';
import '../../booking/data/models/booking_model.dart';
import '../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../data/bookings_repository.dart';
import '../domain/booking_status.dart';

class ActivitiesState {
  final BookingStatusFilter currentTab;
  final List<BookingModel> bookings;
  final bool loading;
  final String? error;
  final bool canLoadMore;
  final int nextPage;

  const ActivitiesState({
    required this.currentTab,
    this.bookings = const [],
    this.loading = false,
    this.error,
    this.canLoadMore = false,
    this.nextPage = 1,
  });

  ActivitiesState copyWith({
    BookingStatusFilter? currentTab,
    List<BookingModel>? bookings,
    bool? loading,
    String? error,
    bool? canLoadMore,
    int? nextPage,
  }) {
    return ActivitiesState(
      currentTab: currentTab ?? this.currentTab,
      bookings: bookings ?? this.bookings,
      loading: loading ?? this.loading,
      error: error,
      canLoadMore: canLoadMore ?? this.canLoadMore,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

class ActivitiesCubit extends Cubit<ActivitiesState> {
  final BookingsRepository repository;
  final TicketsRemoteDataSource ticketsDs;

  ActivitiesCubit({required this.repository, required this.ticketsDs})
    : super(const ActivitiesState(currentTab: BookingStatusFilter.active));

  Future<void> loadTab(BookingStatusFilter tab) async {
    // Guard: avoid reloading same tab if we already have data and not forced
    if (state.currentTab == tab &&
        state.bookings.isNotEmpty &&
        !state.loading) {
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(currentTab: tab, loading: true, error: null));
    try {
      final res = await repository.fetch(filter: tab, page: 1);
      if (isClosed) return;
      emit(
        state.copyWith(
          bookings: res.items,
          loading: false,
          canLoadMore: res.hasMore,
          nextPage: res.nextPage,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    // إجبار إعادة التحميل حتى لو كانت البيانات موجودة
    if (isClosed) return;
    // إعادة تعيين الحالة لضمان التحديث الكامل
    emit(state.copyWith(loading: true, error: null, bookings: []));
    try {
      final res = await repository.fetch(filter: state.currentTab, page: 1);
      if (isClosed) return;
      emit(
        state.copyWith(
          bookings: res.items,
          loading: false,
          canLoadMore: res.hasMore,
          nextPage: res.nextPage,
          error: null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (!state.canLoadMore || state.loading) return;
    if (isClosed) return;
    emit(state.copyWith(loading: true));
    try {
      final res = await repository.fetch(
        filter: state.currentTab,
        page: state.nextPage,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          bookings: [...state.bookings, ...res.items],
          loading: false,
          canLoadMore: res.hasMore,
          nextPage: res.nextPage,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
