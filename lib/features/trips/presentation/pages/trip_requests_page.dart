import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../events/presentation/pages/my_event_requests_page.dart';
import '../../di/trips_injection.dart' as trips_di;
import '../cubit/trip_requests_cubit.dart';
import '../cubit/trip_requests_state.dart';
import '../widgets/trip_request_card.dart';

class TripRequestsPage extends StatefulWidget {
  const TripRequestsPage({super.key});

  @override
  State<TripRequestsPage> createState() => _TripRequestsPageState();
}

class _TripRequestsPageState extends State<TripRequestsPage> {
  late final TripRequestsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = trips_di.sl<TripRequestsCubit>();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickPreferredDateFilter() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final state = _cubit.state;
    final initial = state.dateFilter ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null && mounted) {
      _cubit.setPreferredDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_2, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'school_trips_title'.tr(),
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
          ),
        ),
        body: BlocBuilder<TripRequestsCubit, TripRequestsState>(
          builder: (context, state) {
            if (state.isLoading && state.requests.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.hasError && state.requests.isEmpty) {
              return _buildErrorState(context, state.errorMessage ?? '');
            }

            final visible = state.visibleRequests;

            return RefreshIndicator(
              onRefresh: () => _cubit.load(forceRefresh: true),
              color: theme.primaryColor,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GestureDetector(
                                onTap: _pickPreferredDateFilter,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Iconsax.calendar_1,
                                          size: 20,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'filter_trips_by_date'.tr(),
                                              style: const TextStyle(
                                                fontFamily: 'MontserratArabic',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              state.dateFilter != null
                                                  ? DateFormat.yMMMMd(
                                                      context.locale.toString(),
                                                    ).format(state.dateFilter!)
                                                  : 'select_date'.tr(),
                                              style: TextStyle(
                                                fontFamily: 'MontserratArabic',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: state.dateFilter != null
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (state.dateFilter != null)
                                        IconButton(
                                          onPressed: () =>
                                              _cubit.clearPreferredDateFilter(),
                                          icon: const Icon(
                                            Iconsax.close_circle,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          tooltip: 'all'.tr(),
                                        )
                                      else
                                        const Icon(
                                          Iconsax.arrow_down_1,
                                          size: 20,
                                          color: Color(0xFF94A3B8),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const MyEventRequestsPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.calendar_edit,
                                          size: 22,
                                          color: theme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'private_events'.tr(),
                                            style: const TextStyle(
                                              fontFamily: 'MontserratArabic',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Iconsax.arrow_left_2,
                                          size: 18,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            state.requests.isNotEmpty &&
                                state.dateFilter != null
                            ? _buildNoTripsForDateState(theme)
                            : _buildEmptyState(theme),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final request = visible[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TripRequestCard(
                              request: request,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/school-trips/details',
                                  arguments: request,
                                );
                              },
                            ),
                          );
                        }, childCount: visible.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/school-trips/create',
            );
            if (result != null) {
              _cubit.load(forceRefresh: true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('trip_request_created')),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }
          },
          backgroundColor: theme.primaryColor,
          elevation: 4,
          highlightElevation: 8,
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: Text(
            'create_trip_request'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFamily: 'MontserratArabic',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTripsForDateState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.calendar_remove, size: 56, color: theme.primaryColor),
        const SizedBox(height: 20),
        Text(
          'no_trips_for_selected_date'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => _cubit.clearPreferredDateFilter(),
          child: Text(
            'all'.tr(),
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Iconsax.bus5, size: 64, color: theme.primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          'no_trip_requests'.tr(),
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'start_first_trip_request'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _cubit.load(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Iconsax.refresh),
              label: Text(
                'retry'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
