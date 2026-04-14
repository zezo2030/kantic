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
            height: 160,
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
            height: 168,
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
        : null;
    final durationLabel = _buildDurationLabel();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionPlanDetailsPage(plan: plan),
        ),
      ),
      child: Container(
        width: 185,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: resolvedUrl == null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3460).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ─── Background Image ───
              if (resolvedUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: resolvedUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF1A1A2E)),
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
                  ),
                ),

              // ─── Dark overlay ───
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(resolvedUrl != null ? 0.3 : 0.0),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Decorative circles (only if no image) ───
              if (resolvedUrl == null) ...[
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryRed.withOpacity(0.15),
                    ),
                  ),
                ),
              ],

              // ─── Content ───
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.card, color: AppColors.primaryRed, size: 20),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      plan.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),

                    // Price + Duration
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${plan.price.toStringAsFixed(plan.price % 1 == 0 ? 0 : 2)} ${plan.currency.tr()} / $durationLabel',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plan.isGiftable)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.gift, size: 16, color: Colors.amber),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDurationLabel() {
    if (plan.durationMonths == 1) return 'monthly'.tr();
    if (plan.durationMonths == 12) return 'yearly'.tr();
    return '${plan.durationMonths} ${'months'.tr()}';
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
            height: 168,
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
    final gradient = _isTicket
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B2FF7), Color(0xFF9D46FF), Color(0xFFBF6FFF)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00897B), Color(0xFF00ACC1), Color(0xFF26C6DA)],
          );

    final resolvedUrl = product.imageUrl != null && product.imageUrl!.isNotEmpty
        ? resolveFileUrl(product.imageUrl!)
        : null;

    final accentColor = _isTicket ? const Color(0xFF7B2FF7) : const Color(0xFF00897B);
    final categoryLabel = _isTicket ? 'ticket'.tr() : 'hours'.tr();
    final categoryIcon = _isTicket ? Iconsax.ticket : Iconsax.clock;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OfferProductDetailsPage(product: product),
        ),
      ),
      child: Container(
        width: 185,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: resolvedUrl == null ? gradient : null,
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ─── Background Image ───
              if (resolvedUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: resolvedUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: accentColor),
                    errorWidget: (_, __, ___) => Container(color: accentColor),
                  ),
                ),

              // ─── Dark overlay ───
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(resolvedUrl != null ? 0.2 : 0.0),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Decorative circles (only if no image) ───
              if (resolvedUrl == null) ...[
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              ],

              // ─── Content ───
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(categoryIcon, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                categoryLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (product.isGiftable)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.gift, size: 14, color: Colors.amber),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),

                    // Price
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)} ${product.currency.tr()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
