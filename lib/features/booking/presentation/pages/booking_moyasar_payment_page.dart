import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/domain/usecases/confirm_payment_usecase.dart';

/// Card payment for a booking when the backend returns no Tap redirect URL.
class BookingMoyasarPaymentPage extends StatelessWidget {
  const BookingMoyasarPaymentPage({
    super.key,
    required this.bookingId,
    required this.paymentId,
    required this.amount,
  });

  final String bookingId;
  final String paymentId;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final paymentConfig = PaymentConfig(
      publishableApiKey: ApiConstants.moyasarPublishableKey,
      amount: (amount * 100).round(),
      currency: 'SAR',
      description: 'Booking payment',
      metadata: {
        'flow': 'booking',
        'bookingId': bookingId,
        'paymentId': paymentId,
      },
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
        title: Text('credit_card'.tr()),
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
                    try {
                      payments_di.initPayments();
                    } catch (_) {}
                    final useCase = payments_di.sl<ConfirmPaymentUseCase>();
                    final confirm = await useCase(
                      bookingId: bookingId,
                      paymentId: paymentId,
                      chargeId: result.id,
                    );
                    if (!context.mounted) return;
                    if (confirm.success) {
                      Navigator.of(context).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('payment_failed_title'.tr()),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                    return;
                  }

                  if (result.status == PaymentStatus.failed && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('payment_failed_title'.tr()),
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
    return 'payment_failed_title'.tr();
  }
}
