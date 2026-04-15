import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moyasar/moyasar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/presentation/widgets/moyasar_checkout_view.dart';
import '../cubit/wallet_cubit.dart';

class WalletMoyasarPaymentPage extends StatelessWidget {
  final String paymentId;
  final double amount;

  const WalletMoyasarPaymentPage({
    super.key,
    required this.paymentId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final paymentConfig = buildMoyasarPaymentConfig(
      amount: amount,
      description: 'Wallet recharge',
      metadata: {'flow': 'wallet_recharge', 'paymentId': paymentId},
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('recharge_wallet'.tr()),
        backgroundColor: AppColors.surfaceColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MoyasarCheckoutView(
            config: paymentConfig,
            applePayTitle: 'apple_pay'.tr(),
            onPaymentResult: (result) async {
              if (result is PaymentResponse) {
                final isPaid = result.status == PaymentStatus.paid ||
                    result.status == PaymentStatus.authorized;
                if (isPaid) {
                  final confirmed = await context
                      .read<WalletCubit>()
                      .confirmRechargePayment(
                        paymentId: paymentId,
                        moyasarPaymentId: result.id,
                      );
                  if (!context.mounted) return;
                  Navigator.of(context).pop(confirmed);
                  return;
                }

                if (result.status == PaymentStatus.failed && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('recharge_failed'.tr()),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
                return;
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      extractMoyasarError(result, 'recharge_failed'.tr()),
                    ),
                    backgroundColor: AppColors.errorColor,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
