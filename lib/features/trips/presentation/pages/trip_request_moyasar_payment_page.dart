import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/domain/usecases/confirm_payment_usecase.dart';
import '../../../payments/presentation/widgets/moyasar_checkout_view.dart';

/// دفع طلب رحلة مدرسية بالبطاقة عبر Moyasar (يُطابق مسار شحن المحفظة و `/payments/confirm`).
class TripRequestMoyasarPaymentPage extends StatelessWidget {
  const TripRequestMoyasarPaymentPage({
    super.key,
    required this.tripRequestId,
    required this.paymentId,
    required this.amount,
  });

  final String tripRequestId;
  final String paymentId;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final paymentConfig = buildMoyasarPaymentConfig(
      amount: amount,
      description: 'School trip request',
      metadata: {
        'flow': 'trip_request',
        'tripRequestId': tripRequestId,
        'paymentId': paymentId,
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('trip_payment_section_title'.tr()),
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
                  try {
                    payments_di.initPayments();
                  } catch (_) {}
                  final useCase = payments_di.sl<ConfirmPaymentUseCase>();
                  final confirm = await useCase(
                    tripRequestId: tripRequestId,
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
                    content: Text(
                      extractMoyasarError(result, 'unknown_error'.tr()),
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
