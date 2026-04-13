import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/subscription_plan_model.dart';
import 'subscription_checkout_page.dart';

class SubscriptionPlanDetailsPage extends StatelessWidget {
  final SubscriptionPlanModel plan;

  const SubscriptionPlanDetailsPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plan.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${plan.price.toStringAsFixed(0)} ${plan.currency}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('${'subscriptions_usage_mode'.tr()}: ${plan.usageMode}'),
          if (plan.totalHours != null)
            Text('${'subscriptions_total_hours'.tr()}: ${plan.totalHours}'),
          if (plan.dailyHoursLimit != null)
            Text(
              '${'subscriptions_daily_limit'.tr()}: ${plan.dailyHoursLimit}',
            ),
          const SizedBox(height: 16),
          if (plan.description != null && plan.description!.isNotEmpty)
            Text(plan.description!),
          if (plan.termsAndConditions != null &&
              plan.termsAndConditions!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'terms_and_conditions'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(plan.termsAndConditions!),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionCheckoutPage(plan: plan),
                ),
              ),
              child: Text('subscribe_now'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
