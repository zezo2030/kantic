import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../cubit/subscription_purchase_cubit.dart';
import '../../data/models/subscription_plan_model.dart';
import 'my_subscriptions_page.dart';
import 'subscription_details_page.dart';

class SubscriptionCheckoutPage extends StatefulWidget {
  final SubscriptionPlanModel plan;

  const SubscriptionCheckoutPage({super.key, required this.plan});

  @override
  State<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  bool _accepted = false;
  Map<String, dynamic>? _quote;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<SubscriptionPurchaseCubit>()..fetchQuote(widget.plan.id),
        ),
        BlocProvider.value(value: payments_di.sl<PaymentCubit>()),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text('subscription_checkout'.tr())),
        body: MultiBlocListener(
          listeners: [
            BlocListener<PaymentCubit, PaymentState>(
              listener: (context, state) {
                if (state is PaymentSuccess) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MySubscriptionsPage(),
                    ),
                    (r) => r.isFirst,
                  );
                }
              },
            ),
            BlocListener<SubscriptionPurchaseCubit, SubscriptionPurchaseState>(
              listener: (context, state) {
                if (state is SubscriptionPurchaseQuoteReady) {
                  setState(() => _quote = state.quote);
                }
                if (state is SubscriptionPurchaseLoading) {
                  setState(() => _submitting = true);
                }
                if (state is SubscriptionPurchaseCreated) {
                  setState(() => _submitting = false);
                  final r = state.result;
                  final paymentRequired = r['paymentRequired'] == true;
                  final purchaseId = r['id']?.toString() ?? '';
                  final total = (r['totalPrice'] is num)
                      ? (r['totalPrice'] as num).toDouble()
                      : double.tryParse('${r['totalPrice']}') ??
                          widget.plan.price;
                  if (!paymentRequired && purchaseId.isNotEmpty) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SubscriptionDetailsPage(purchaseId: purchaseId),
                      ),
                    );
                    return;
                  }
                  if (paymentRequired && purchaseId.isNotEmpty) {
                    payments_di.initPayments();
                    context.read<PaymentCubit>().payForSubscriptionPurchase(
                          subscriptionPurchaseId: purchaseId,
                          amount: total,
                        );
                  }
                }
                if (state is SubscriptionPurchaseError) {
                  setState(() => _submitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: Builder(
            builder: (context) {
              if (_quote == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final q = _quote!;
              final price = (q['totalPrice'] is num)
                  ? (q['totalPrice'] as num).toDouble()
                  : 0.0;
              final currency = q['currency']?.toString() ?? 'SAR';
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${price.toStringAsFixed(0)} $currency',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _accepted,
                          onChanged: _submitting
                              ? null
                              : (v) => setState(() => _accepted = v ?? false),
                          title: Text('accept_terms_subscription'.tr()),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: (!_accepted || _submitting)
                              ? null
                              : () => context
                                  .read<SubscriptionPurchaseCubit>()
                                  .submitPurchase(
                                    planId: widget.plan.id,
                                    acceptedTerms: true,
                                  ),
                          child: Text('pay_continue'.tr()),
                        ),
                      ],
                    ),
                  ),
                  if (_submitting)
                    const ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
