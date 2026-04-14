// My EventRequests Page - Presentation Layer
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../auth/di/auth_injection.dart';
import '../../../../core/theme/app_colors.dart';
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

class _MyEventRequestsViewState extends State<_MyEventRequestsView>
    with TickerProviderStateMixin {
  String? _selectedStatus;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Iconsax.arrow_left_2,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
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
            return _buildLoadingState();
          }

          if (state is EventRequestsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is EventRequestsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
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
                        const SizedBox(height: 8),
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
                            child: TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 300 + (index * 50),
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: EventRequestCard(
                                request: request,
                                onTap: () {
                                  HapticFeedback.selectionClick();
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
                            ),
                          );
                        }, childCount: state.requests.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.heavyImpact();
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.add, color: Colors.white, size: 20),
          ),
          label: Text(
            'create_new_request'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFamily: 'MontserratArabic',
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'loading'.tr(),
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.greyMedium,
            ),
          ),
        ],
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
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedStatus = entry.key == 'all' ? null : entry.key;
                });
                context.read<EventRequestCubit>().getRequests(
                  status: _selectedStatus,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontFamily: 'MontserratArabic',
                    fontSize: 13,
                  ),
                ),
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
        const SizedBox(height: 40),
        // Animated illustration
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryOrange.withOpacity(0.1),
                AppColors.primaryRed.withOpacity(0.08),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.calendar_add,
                  size: 48,
                  color: AppColors.primaryRed.withOpacity(0.7),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'no_requests'.tr(),
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'start_by_creating_special_request'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Hint text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.tick_circle,
                size: 18,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'tap_below_to_start'.tr(),
                style: TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.warning_2,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'oops_something_went_wrong'.tr(),
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<EventRequestCubit>().getRequests(
                  status: _selectedStatus,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.primaryRed],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.refresh, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'retry'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
