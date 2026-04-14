import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/models/subscription_plan_model.dart';
import 'subscription_checkout_page.dart';

class SubscriptionPlanDetailsPage extends StatelessWidget {
  final SubscriptionPlanModel plan;

  const SubscriptionPlanDetailsPage({super.key, required this.plan});

  String _buildDurationLabel() {
    if (plan.durationMonths == 1) return 'monthly'.tr();
    if (plan.durationMonths == 12) return 'yearly'.tr();
    return '${plan.durationMonths} ${'months'.tr()}';
  }

  String _usageModeLabel(String value) {
    switch (value.toLowerCase().trim()) {
      case 'daily_limited':
        return 'subscription_usage_daily_limited'.tr();
      case 'monthly_pool':
        return 'subscription_usage_monthly_pool'.tr();
      case 'unlimited':
        return 'subscription_unlimited'.tr();
      case 'flexible_total_hours':
        return 'flexible_total_hours'.tr();
      case 'daily_unlimited':
        return 'daily_unlimited'.tr();
      default:
        return value.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = plan.imageUrl != null && plan.imageUrl!.isNotEmpty
        ? resolveFileUrl(plan.imageUrl!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        title: Text('subscription_plan_details'.tr()),
        centerTitle: true,
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'MontserratArabic', // Fallback to ensure matching style
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (resolvedUrl != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: resolvedUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.luxurySurfaceVariant),
                  errorWidget: (_, __, ___) => Container(color: AppColors.luxurySurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildBody(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Gift Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                if (plan.isGiftable)
                  Container(
                    margin: const EdgeInsets.only(left: 12, right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.luxuryGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Iconsax.gift, color: AppColors.luxuryGold, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Price Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${plan.price.toStringAsFixed(plan.price % 1 == 0 ? 0 : 2)} ${plan.currency.tr()}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${_buildDurationLabel()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Key Features Section
            Text(
              'subscription_plan_summary'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildModernFeatureItem(
                  context,
                  icon: Iconsax.timer_1,
                  title: 'subscriptions_usage_mode'.tr(),
                  value: _usageModeLabel(plan.usageMode),
                ),
                if (plan.totalHours != null)
                  _buildModernFeatureItem(
                    context,
                    icon: Iconsax.clock,
                    title: 'subscriptions_total_hours'.tr(),
                    value: '${plan.totalHours} ${'hours'.tr()}',
                  ),
                if (plan.dailyHoursLimit != null)
                  _buildModernFeatureItem(
                    context,
                    icon: Iconsax.flash_1,
                    title: 'subscriptions_daily_limit'.tr(),
                    value: '${plan.dailyHoursLimit} ${'hours'.tr()}',
                  ),
              ],
            ),

            const SizedBox(height: 32),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              _buildSectionTitle('about_plan'.tr()),
              const SizedBox(height: 12),
              Text(
                plan.description!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (plan.termsAndConditions != null &&
                plan.termsAndConditions!.isNotEmpty) ...[
              _buildSectionTitle('terms_and_conditions'.tr()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.luxurySurfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  plan.termsAndConditions!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 60), // Extra safety spacing
          ],
        ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModernFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48 - 12) / 2, // 2 items per row max
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.luxurySurfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionCheckoutPage(plan: plan),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          icon: const Icon(Iconsax.card_send, size: 22),
          label: Text(
            'subscribe_now'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
