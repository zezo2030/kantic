import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moyasar/moyasar.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
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
    final paymentConfig = PaymentConfig(
      publishableApiKey: ApiConstants.moyasarPublishableKey,
      amount: (amount * 100).round(),
      currency: 'SAR',
      description: 'Wallet recharge',
      metadata: {'flow': 'wallet_recharge', 'paymentId': paymentId},
      supportedNetworks: const [
        PaymentNetwork.visa,
        PaymentNetwork.mada,
        PaymentNetwork.masterCard,
      ],
      creditCard: CreditCardConfig(
        saveCard: false,
        manual: false,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('recharge_wallet'.tr()),
        backgroundColor: AppColors.surfaceColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: CreditCard(
              config: paymentConfig,
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
                      content: Text(_extractMoyasarError(result)),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              },
              locale: context.locale.languageCode == 'ar'
                  ? const Localization.ar()
                  : const Localization.en(),
            ),
          ),
        ),
      ),
    );
  }

  String _extractMoyasarError(dynamic result) {
    if (result is ApiError) return result.message;
    if (result is AuthError) return result.message;
    if (result is ValidationError) return result.message;
    if (result is PaymentCanceledError) return result.message;
    if (result is UnprocessableTokenError) return result.message;
    if (result is TimeoutError) return result.message;
    if (result is NetworkError) return result.message;
    if (result is UnspecifiedError) return result.message;
    return 'تعذر إتمام الدفع، حاول مرة أخرى';
  }
}
