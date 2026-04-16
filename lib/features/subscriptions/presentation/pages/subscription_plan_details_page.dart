import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/subscription_plan_model.dart';
import 'subscription_checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/url_utils.dart';

class SubscriptionPlanDetailsPage extends StatelessWidget {
  final SubscriptionPlanModel plan;

  const SubscriptionPlanDetailsPage({super.key, required this.plan});

  String _buildDurationLabel() {
    if (plan.durationMonths == 1) return 'monthly'.tr();
    if (plan.durationMonths == 12) return 'yearly'.tr();
    return '${plan.durationMonths} ${'months'.tr()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildBody(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final bool hasImage = plan.imageUrl != null && plan.imageUrl!.isNotEmpty;
    return SliverAppBar(
      expandedHeight: hasImage ? 340 : 120,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.8),
          child: IconButton(
            icon: const Icon(
              Iconsax.arrow_right_3,
              color: AppColors.primaryRed,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        title: !hasImage 
            ? Text(
                'subscription_plan_details'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
        centerTitle: true,
        background: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'plan_${plan.id}',
                    child: CachedNetworkImage(
                      imageUrl: resolveFileUrl(plan.imageUrl!),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Container(
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Gift Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                if (plan.isGiftable)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.luxuryGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.luxuryGold.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Iconsax.gift, color: AppColors.luxuryGold, size: 26),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Subscription Details (about_plan)
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              _buildSectionTitle('about_plan'.tr(), Iconsax.info_circle),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  plan.description!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 3. عدد الساعات والفترة (Hours and Duration / Key Features)
            _buildSectionTitle('subscription_plan_summary'.tr(), Iconsax.star),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (plan.totalHours != null)
                  _buildModernFeatureItem(
                    context,
                    icon: Iconsax.clock,
                    title: 'subscriptions_total_hours'.tr(),
                    value: '${plan.totalHours!.toInt()} ${'hours'.tr()}',
                  ),
                if (plan.dailyHoursLimit != null)
                  _buildModernFeatureItem(
                    context,
                    icon: Iconsax.flash_1,
                    title: 'subscriptions_daily_limit'.tr(),
                    value: '${plan.dailyHoursLimit!.toInt()} ${'hours'.tr()}',
                  ),
                _buildModernFeatureItem(
                  context,
                  icon: Iconsax.calendar,
                  title: context.locale.languageCode == 'ar' ? 'الفترة' : 'Duration',
                  value: _buildDurationLabel(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. ملخص الاشتراك (Price Tag / Summary)
            _buildSectionTitle(context.locale.languageCode == 'ar' ? 'ملخص الاشتراك' : 'Subscription Summary', Iconsax.wallet_3),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.locale.languageCode == 'ar' ? 'السعر النهائي' : 'Final Price',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${plan.price.toStringAsFixed(plan.price % 1 == 0 ? 0 : 2)} ${plan.currency.tr()}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ ${_buildDurationLabel()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Terms and Conditions
            if (plan.termsAndConditions != null &&
                plan.termsAndConditions!.isNotEmpty) ...[
              _buildSectionTitle('terms_and_conditions'.tr(), Iconsax.document_text),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.luxurySurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.info_circle, size: 20, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        plan.termsAndConditions!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 80), // Extra safety spacing
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
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
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          icon: const Icon(Iconsax.card_send, size: 24),
          label: Text(
            'subscribe_now'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
