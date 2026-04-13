import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../../activities/data/bookings_api.dart';
import '../../activities/data/bookings_repository.dart';
import '../../activities/domain/booking_status.dart';
import 'activities_cubit.dart';
import '../../booking/presentation/pages/booking_details_page.dart';
import 'widgets/booking_card.dart';
import '../../auth/presentation/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ActivitiesCubit(
        repository: BookingsRepositoryImpl(api: BookingsApi()),
        ticketsDs: TicketsRemoteDataSourceImpl(dio: DioClient.instance),
      ),
      child: const _ActivitiesView(),
    );
  }
}

class _ActivitiesView extends StatefulWidget {
  const _ActivitiesView();

  @override
  State<_ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<_ActivitiesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ActivitiesCubit>().loadTab(BookingStatusFilter.active);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivitiesCubit, ActivitiesState>(
      builder: (context, state) {
        // تحديث التبويب النشط بناءً على الحالة
        if (state.currentTab == BookingStatusFilter.active &&
            _tabController.index != 0) {
          _tabController.animateTo(0);
        } else if (state.currentTab == BookingStatusFilter.ended &&
            _tabController.index != 1) {
          _tabController.animateTo(1);
        }

        return Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'tab_active'.tr()),
                  Tab(text: 'tab_ended'.tr()),
                ],
                indicatorColor: AppColors.primaryRed,
                labelColor: AppColors.primaryRed,
                unselectedLabelColor: Colors.grey,
                onTap: (index) {
                  final filter = index == 0
                      ? BookingStatusFilter.active
                      : BookingStatusFilter.ended;
                  context.read<ActivitiesCubit>().loadTab(filter);
                },
              ),
            ),
            // Content
            Expanded(child: _buildContent(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ActivitiesState state) {
    if (state.loading && state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!),
            const SizedBox(height: 8),
            CustomButton(
              onPressed: () =>
                  context.read<ActivitiesCubit>().loadTab(state.currentTab),
              text: 'retry',
              width: 150,
              useGradient: true,
            ),
          ],
        ),
      );
    }

    if (state.bookings.isEmpty && !state.loading) {
      return Center(child: Text('no_bookings_found'.tr()));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => context.read<ActivitiesCubit>().refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200 &&
                  state.canLoadMore &&
                  !state.loading) {
                context.read<ActivitiesCubit>().loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length + (state.canLoadMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.bookings.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final booking = state.bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BookingCard(
                    booking: booking,
                    ticketsDs: context.read<ActivitiesCubit>().ticketsDs,
                    onDetails: () async {
                      // الانتقال إلى صفحة التفاصيل وانتظار النتيجة
                      final result = await Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (_, animation, __) => FadeTransition(
                            opacity: animation,
                            child: BookingDetailsPage(booking: booking),
                          ),
                          transitionsBuilder: (_, animation, __, child) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation);
                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                      // إذا تم إرجاع true (مثل بعد الدفع أو الإلغاء)، قم بتحديث البيانات
                      if (result == true && mounted) {
                        // إضافة تأخير بسيط لضمان تحديث البيانات من الخادم
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          await context.read<ActivitiesCubit>().refresh();
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
        // مؤشر تحميل أثناء التحديث
        if (state.loading && state.bookings.isNotEmpty)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
