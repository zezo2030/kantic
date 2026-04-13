// My EventRequests Page - Presentation Layer
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../auth/di/auth_injection.dart';
import '../cubit/event_request_cubit.dart';
import '../cubit/event_request_state.dart';
import '../widgets/event_request_card.dart';
import 'create_event_request_page.dart';
import 'event_request_details_page.dart';

class MyEventRequestsPage extends StatelessWidget {
  const MyEventRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EventRequestCubit>()..getRequests(),
      child: const _MyEventRequestsView(),
    );
  }
}

class _MyEventRequestsView extends StatefulWidget {
  const _MyEventRequestsView();

  @override
  State<_MyEventRequestsView> createState() => _MyEventRequestsViewState();
}

class _MyEventRequestsViewState extends State<_MyEventRequestsView> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
          'event_requests'.tr(),
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
      body: BlocBuilder<EventRequestCubit, EventRequestState>(
        builder: (context, state) {
          if (state is EventRequestsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventRequestsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is EventRequestsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<EventRequestCubit>().getRequests(
                  status: _selectedStatus == 'all' ? null : _selectedStatus,
                );
              },
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
                        _buildFilterChips(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (state.requests.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEmptyState(context, theme),
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
                            child: EventRequestCard(
                              request: request,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventRequestDetailsPage(
                                      requestId: request.id,
                                    ),
                                  ),
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
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => sl<EventRequestCubit>(),
                child: const CreateEventRequestPage(),
              ),
            ),
          ).then((_) {
            context.read<EventRequestCubit>().getRequests(
              status: _selectedStatus == 'all' ? null : _selectedStatus,
            );
          });
        },
        backgroundColor: theme.primaryColor,
        elevation: 4,
        highlightElevation: 8,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          'create_new_request'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'MontserratArabic',
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final Map<String, String> statusOptions = {
      'all': 'all'.tr(),
      'submitted': 'event_status_submitted'.tr(),
      'quoted': 'event_status_quoted'.tr(),
      'confirmed': 'event_status_confirmed'.tr(),
      'rejected': 'event_status_rejected'.tr(),
    };

    final currentStatus = _selectedStatus ?? 'all';
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: statusOptions.entries.map((entry) {
          final isSelected = currentStatus == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(
                  entry.value,
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
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = entry.key == 'all' ? null : entry.key;
                  });
                  context.read<EventRequestCubit>().getRequests(
                    status: _selectedStatus,
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
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
          child: Icon(Iconsax.reserve, size: 64, color: theme.primaryColor),
        ),
        const SizedBox(height: 24),
        Text(
          'no_requests'.tr(),
          style: TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'start_by_creating_special_request'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
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
              onPressed: () {
                context.read<EventRequestCubit>().getRequests(
                  status: _selectedStatus,
                );
              },
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
                style: TextStyle(
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
