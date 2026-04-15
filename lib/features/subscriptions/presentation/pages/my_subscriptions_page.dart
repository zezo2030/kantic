import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/di/auth_injection.dart';
import '../../data/models/subscription_purchase_model.dart';
import '../cubit/my_subscriptions_cubit.dart';
import 'subscription_details_page.dart';

class MySubscriptionsPage extends StatelessWidget {
  const MySubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MySubscriptionsCubit>()..refresh(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F4F0),
        appBar: AppBar(
          title: Text(
            'my_subscriptions'.tr(),
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: BlocBuilder<MySubscriptionsCubit, MySubscriptionsState>(
          builder: (context, state) {
            if (state is MySubscriptionsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }
            if (state is MySubscriptionsError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.warning_2,
                      size: 48,
                      color: AppColors.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<MySubscriptionsCubit>().refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'retry'.tr(),
                        style: const TextStyle(fontFamily: 'MontserratArabic'),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is MySubscriptionsLoaded) {
              if (state.items.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<MySubscriptionsCubit>().refresh(),
                color: AppColors.primaryRed,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: state.items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    if (i == state.items.length) {
                      if (state.page >= state.totalPages) {
                        return const SizedBox(height: 40);
                      }
                      return Center(
                        child: TextButton(
                          onPressed: () =>
                              context.read<MySubscriptionsCubit>().loadMore(),
                          child: Text(
                            'load_more'.tr(),
                            style: const TextStyle(
                              fontFamily: 'MontserratArabic',
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    final p = state.items[i];
                    return _SubscriptionCard(purchase: p, index: i);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.receipt_item,
              size: 64,
              color: AppColors.primaryRed,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'my_subscriptions'.tr(),
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'no_data_available'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPurchaseModel purchase;
  final int index;

  const _SubscriptionCard({required this.purchase, required this.index});

  @override
  Widget build(BuildContext context) {
    final daysLeft = purchase.endsAt.difference(DateTime.now()).inDays;
    final isExpired = daysLeft <= 0;
    final isActive = purchase.status.toLowerCase() == 'active' && !isExpired;
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionDetailsPage(purchaseId: purchase.id),
        ),
      ),
      child:
          Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryRed.withOpacity(0.05)
                            : isExpired
                            ? AppColors.errorColor.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryRed
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.ticket,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  purchase.planTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'MontserratArabic',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Iconsax.calendar_1,
                                      size: 14,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${dateFormat.format(purchase.startedAt)} - ${dateFormat.format(purchase.endsAt)}',
                                      style: const TextStyle(
                                        fontFamily: 'MontserratArabic',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatusPill(
                            label: isActive
                                ? 'active'.tr()
                                : isExpired
                                ? 'expired'.tr()
                                : purchase.status,
                            isActive: isActive,
                            isExpired: isExpired,
                          ),
                          Row(
                            children: [
                              Text(
                                'subscription_details'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Iconsax.arrow_left_2,
                                size: 16,
                                color: AppColors.primaryRed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index))
              .slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 500.ms,
              ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isExpired;

  const _StatusPill({
    required this.label,
    required this.isActive,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF66BB6A)
        : isExpired
        ? const Color(0xFFE57373)
        : const Color(0xFFFFB74D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
