import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../cubit/subscription_plans_cubit.dart';
import '../widgets/subscription_plan_card.dart';
import 'subscription_plan_details_page.dart';

/// قائمة خطط الاشتراك لفرع
class SubscriptionPlansPage extends StatelessWidget {
  final String branchId;
  final String? branchName;

  const SubscriptionPlansPage({
    super.key,
    required this.branchId,
    this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SubscriptionPlansCubit>()..load(branchId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('subscriptions_plans_title'.tr()),
        ),
        body: BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
          builder: (context, state) {
            if (state is SubscriptionPlansLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SubscriptionPlansError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              );
            }
            if (state is SubscriptionPlansLoaded) {
              if (state.plans.isEmpty) {
                return Center(child: Text('subscriptions_empty'.tr()));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.plans.length,
                itemBuilder: (context, i) {
                  final p = state.plans[i];
                  return SubscriptionPlanCard(
                    plan: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubscriptionPlanDetailsPage(plan: p),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
