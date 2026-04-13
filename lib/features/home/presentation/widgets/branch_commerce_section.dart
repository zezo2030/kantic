import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../subscriptions/presentation/cubit/subscription_plans_cubit.dart';
import '../../../subscriptions/presentation/pages/subscription_plans_page.dart';
import '../../../offer_products/presentation/cubit/offer_products_cubit.dart';
import '../../../offer_products/presentation/pages/offer_products_page.dart';

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
          BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
            builder: (context, state) {
              if (state is! SubscriptionPlansLoaded || state.plans.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CommerceCard(
                  icon: Iconsax.card,
                  title: 'branch_subscriptions_section'.tr(),
                  subtitle: 'branch_subscriptions_subtitle'.tr(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscriptionPlansPage(branchId: branchId),
                    ),
                  ),
                ),
              );
            },
          ),
          BlocBuilder<OfferProductsCubit, OfferProductsState>(
            builder: (context, state) {
              if (state is! OfferProductsLoaded) {
                return const SizedBox.shrink();
              }
              final has = state.ticketOffers.isNotEmpty ||
                  state.hoursOffers.isNotEmpty;
              if (!has) return const SizedBox.shrink();
              return _CommerceCard(
                icon: Iconsax.gift,
                title: 'branch_offer_products_section'.tr(),
                subtitle: 'branch_offer_products_subtitle'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OfferProductsPage(branchId: branchId),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommerceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CommerceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
