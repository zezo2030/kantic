import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../auth/presentation/widgets/custom_button.dart';
import '../../di/trips_injection.dart' as trips_di;
import '../../domain/entities/trip_request_status.dart';
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
                        _StatusFilterChips(
                          selectedStatus: state.statusFilter,
                          onChanged: (status) => _cubit.load(status: status),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (state.requests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEmptyState(theme),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final request = state.requests[index];
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
                        }, childCount: state.requests.length),
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
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'create_trip_request'.tr(),
            onPressed: () =>
                Navigator.pushNamed(context, '/school-trips/create'),
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

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selectedStatus,
    required this.onChanged,
  });

  final TripRequestStatus? selectedStatus;
  final ValueChanged<TripRequestStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = <TripRequestStatus?>[
      null,
      TripRequestStatus.pending,
      TripRequestStatus.underReview,
      TripRequestStatus.approved,
      TripRequestStatus.invoiced,
      TripRequestStatus.paid,
      TripRequestStatus.completed,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: statuses.map((status) {
          final isSelected = selectedStatus == status;
          final theme = Theme.of(context);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(
                  _statusLabel(context, status),
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontFamily: 'MontserratArabic',
                    fontSize: 13,
                  ),
                ),
                backgroundColor: Colors.white,
                selectedColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? theme.primaryColor
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                onSelected: (_) => onChanged(status),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _statusLabel(BuildContext context, TripRequestStatus? status) {
    if (status == null) return tr('all');
    switch (status) {
      case TripRequestStatus.pending:
        return tr('status_pending');
      case TripRequestStatus.underReview:
        return tr('status_under_review');
      case TripRequestStatus.approved:
        return tr('status_approved');
      case TripRequestStatus.rejected:
        return tr('status_rejected');
      case TripRequestStatus.invoiced:
        return tr('status_invoiced');
      case TripRequestStatus.paid:
        return tr('status_paid');
      case TripRequestStatus.completed:
        return tr('status_completed');
      case TripRequestStatus.cancelled:
        return tr('status_cancelled');
      case TripRequestStatus.unknown:
        return tr('status_unknown');
    }
  }
}
