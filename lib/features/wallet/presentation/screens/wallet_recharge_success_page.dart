import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/routes/app_route_generator.dart';

class WalletRechargeSuccessPage extends StatelessWidget {
  final String paymentId;

  const WalletRechargeSuccessPage({
    super.key,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = paymentId.length > 8
        ? '${paymentId.substring(0, 8)}...'
        : paymentId;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 96,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'payment_success_title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '${tr('transaction_id')}: $shortId',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.main,
                      (route) => false,
                    ),
                    child: Text('back_to_home'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
