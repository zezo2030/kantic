import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../subscriptions/data/models/subscription_plan_model.dart';
import '../../../subscriptions/presentation/cubit/subscription_plans_cubit.dart';
import '../../../subscriptions/presentation/pages/subscription_plan_details_page.dart';
import '../../../offer_products/data/models/offer_product_model.dart';
import '../../../offer_products/presentation/cubit/offer_products_cubit.dart';
import '../../../offer_products/presentation/pages/offer_product_details_page.dart';

/// خطط الاشتراك ومنتجات العروض (كتالوج) لفرع
class BranchCommerceSection extends StatelessWidget {
  final String branchId;

  const BranchCommerceSection({super.key, required this.branchId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<SubscriptionPlansCubit>()..load(branchId),
        ),
        BlocProvider(
          create: (_) => sl<OfferProductsCubit>()..load(branchId),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Subscription Plans ───
          BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
            builder: (context, state) {
              if (state is SubscriptionPlansLoading) {
                return _buildSectionShimmer(context, 'branch_subscriptions_section'.tr());
              }
              if (state is! SubscriptionPlansLoaded || state.plans.isEmpty) {
                return const SizedBox.shrink();
              }
              return _SubscriptionPlansSection(
                plans: state.plans,
                branchId: branchId,
              );
            },
          ),

          // ─── Offer Products ───
          BlocBuilder<OfferProductsCubit, OfferProductsState>(
            builder: (context, state) {
              if (state is OfferProductsLoading) {
                return _buildSectionShimmer(context, 'branch_offer_products_section'.tr());
              }
              if (state is! OfferProductsLoaded) return const SizedBox.shrink();
              final hasOffers =
                  state.ticketOffers.isNotEmpty || state.hoursOffers.isNotEmpty;
              if (!hasOffers) return const SizedBox.shrink();
              return _OfferProductsSection(
                ticketOffers: state.ticketOffers,
                hoursOffers: state.hoursOffers,
                branchId: branchId,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionShimmer(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: Iconsax.card),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => _ShimmerCard(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Subscription Plans Section
// ─────────────────────────────────────────────────────────────
class _SubscriptionPlansSection extends StatelessWidget {
  final List<SubscriptionPlanModel> plans;
  final String branchId;

  const _SubscriptionPlansSection({required this.plans, required this.branchId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _SectionHeader(
                  title: 'branch_subscriptions_section'.tr(),
                  icon: Iconsax.card,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _SubscriptionCard(plan: plans[i], branchId: branchId),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final String branchId;

  const _SubscriptionCard({required this.plan, required this.branchId});

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = plan.imageUrl != null && plan.imageUrl!.isNotEmpty
        ? resolveFileUrl(plan.imageUrl!)
        : '';
        
    final bool isAr = context.locale.languageCode == 'ar';
    final String pricePrefix = isAr ? 'سعر الاشتراك :' : 'Subscription Price :';
    final String formattedPrice = '${plan.price.toStringAsFixed(plan.price % 1 == 0 ? 0 : 2)} ${plan.currency.tr()}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionPlanDetailsPage(plan: plan),
        ),
      ),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: resolvedUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                      )
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRed,
                    const Color(0xFFD81B60),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '$pricePrefix $formattedPrice',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Offer Products Section
// ─────────────────────────────────────────────────────────────
class _OfferProductsSection extends StatelessWidget {
  final List<OfferProductModel> ticketOffers;
  final List<OfferProductModel> hoursOffers;
  final String branchId;

  const _OfferProductsSection({
    required this.ticketOffers,
    required this.hoursOffers,
    required this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    final allOffers = [...ticketOffers, ...hoursOffers];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _SectionHeader(
                  title: 'branch_offer_products_section'.tr(),
                  icon: Iconsax.gift,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: allOffers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _OfferProductCard(
                product: allOffers[i],
                branchId: branchId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferProductCard extends StatelessWidget {
  final OfferProductModel product;
  final String branchId;

  const _OfferProductCard({required this.product, required this.branchId});

  bool get _isTicket => product.offerCategory == 'ticket_based';

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = product.imageUrl != null && product.imageUrl!.isNotEmpty
        ? resolveFileUrl(product.imageUrl!)
        : '';
        
    final bool isAr = context.locale.languageCode == 'ar';
    final String pricePrefix = _isTicket 
        ? (isAr ? 'سعر التذكرة :' : 'Ticket Price :')
        : (isAr ? 'سعر العرض :' : 'Offer Price :');
    final String formattedPrice = '${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)} ${product.currency.tr()}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfferProductDetailsPage(product: product),
        ),
      ),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: resolvedUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                      )
                    : Container(color: Colors.grey[200]),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRed,
                    const Color(0xFFD81B60),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        '$pricePrefix $formattedPrice',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 185,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withOpacity(_animation.value),
        ),
      ),
    );
  }
}
