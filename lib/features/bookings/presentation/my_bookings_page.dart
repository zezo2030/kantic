import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../../activities/data/bookings_api.dart';
import '../../activities/data/bookings_repository.dart';
import '../../activities/domain/booking_status.dart';
import '../../activities/presentation/widgets/booking_card.dart';
import '../../booking/data/models/booking_model.dart';
import '../../booking/presentation/pages/booking_details_page.dart';
import '../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/cubit/auth_state.dart';
import '../../auth/presentation/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Check if user is guest
        if (authState is Guest) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(title: Text('my_bookings'.tr())),
            body: Center(
              child: Text(
                'login_required'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return RepositoryProvider<BookingsRepository>(
          create: (_) => BookingsRepositoryImpl(api: BookingsApi()),
          child: _PremiumBookingsView(
            ticketsDs: TicketsRemoteDataSourceImpl(dio: DioClient.instance),
          ),
        );
      },
    );
  }
}

class _PremiumBookingsView extends StatefulWidget {
  final TicketsRemoteDataSource ticketsDs;
  const _PremiumBookingsView({required this.ticketsDs});

  @override
  State<_PremiumBookingsView> createState() => _PremiumBookingsViewState();
}

enum BookingTab { upcoming, past }

class _PremiumBookingsViewState extends State<_PremiumBookingsView>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _pastBookings = [];

  DateTime? _lastLoadTime;
  bool _isManualRefresh = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this page
    if (_lastLoadTime != null && mounted && !_loading && !_isManualRefresh) {
      final now = DateTime.now();
      if (now.difference(_lastLoadTime!).inSeconds > 2) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isManualRefresh) {
            _load();
          }
        });
      }
    }
  }

  void _refreshBookings() {
    if (mounted) {
      _isManualRefresh = true;
      _load().then((_) {
        if (mounted) {
          setState(() {
            _isManualRefresh = false;
          });
        }
      });
    }
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<BookingsRepository>();
      final res = await repo.fetch(
        filter: BookingStatusFilter.all,
        page: 1,
        pageSize: 100, // Fetch a larger set to distribute between tabs
      );

      final now = DateTime.now();

      final upcoming = <BookingModel>[];
      final past = <BookingModel>[];

      for (var b in res.items) {
        // Assume anything starting after today is upcoming, also today's bookings that are not done
        // For simplicity, anything where startTime is strictly before now is past
        // (This can be adjusted depending on business logic)
        final startTimeLocal = b.startTime.toLocal();

        // Let's add an end time buffer to consider it past.
        // e.g., if it's currently running, it's upcoming?
        // simple rule: is it before now?
        if (startTimeLocal.isBefore(now)) {
          past.add(b);
        } else {
          upcoming.add(b);
        }
      }

      if (mounted) {
        setState(() {
          _upcomingBookings = upcoming;
          _pastBookings = past;
          _loading = false;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Map<DateTime, List<BookingModel>> _groupByDay(
    List<BookingModel> list, {
    bool descending = false,
  }) {
    final Map<DateTime, List<BookingModel>> map = {};
    for (final b in list) {
      final local = b.startTime.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      (map[d] ??= <BookingModel>[]).add(b);
    }
    final entries = map.entries.toList();
    if (descending) {
      entries.sort((a, b) => b.key.compareTo(a.key));
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }
    return Map<DateTime, List<BookingModel>>.fromEntries(entries);
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) return 'today'.tr();
    if (day == tomorrow) return 'tomorrow'.tr();
    if (day == yesterday) return 'yesterday'.tr();

    return DateFormat('EEEE, d MMMM', context.locale.languageCode).format(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryRed,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                elevation: innerBoxIsScrolled ? 4 : 0,
                backgroundColor: AppColors.primaryRed,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'my_bookings'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                      Positioned(
                        right: -20,
                        top: -10,
                        child: Icon(
                          Iconsax.calendar_tick,
                          size: 100,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Icon(
                          Iconsax.ticket,
                          size: 120,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildTabBar()),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(_upcomingBookings, BookingTab.upcoming),
              _buildList(_pastBookings, BookingTab.past),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: [
          Tab(text: 'tab_upcoming'.tr()), // القادمة
          Tab(text: 'tab_past'.tr()), // السابقة
        ],
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, BookingTab tab) {
    if (_loading && bookings.isEmpty) {
      return _buildShimmerLoading();
    }

    if (_error != null && bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.danger, color: Colors.orange, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: _load,
              icon: const Icon(Iconsax.refresh, color: Colors.white, size: 20),
              text: 'retry',
              width: 150,
              useGradient: true,
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return _buildEmptyState(tab);
    }

    final grouped = _groupByDay(bookings, descending: tab == BookingTab.past);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32, top: 4),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        final day = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dayLabel(context, day),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((b) => _buildAnimatedCard(b, tab)),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedCard(BookingModel b, BookingTab tab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: BookingCard(
        booking: b,
        ticketsDs: widget.ticketsDs,
        onDetails: () async {
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, animation, __) => FadeTransition(
                opacity: animation,
                child: BookingDetailsPage(booking: b),
              ),
              transitionsBuilder: (_, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutQuart,
                        ),
                      ),
                  child: child,
                );
              },
            ),
          );
          if (result == true && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _refreshBookings();
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BookingTab tab) {
    final isUpcoming = tab == BookingTab.upcoming;
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpcoming ? Iconsax.calendar_remove : Iconsax.receipt_square,
                size: 72,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isUpcoming
                  ? 'no_bookings_found'.tr()
                  : 'no_previous_bookings'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isUpcoming
                    ? 'discover_branches_and_book_easily'.tr()
                    : 'no_previous_bookings_message'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
            ),
            if (isUpcoming) ...[],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 132,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
