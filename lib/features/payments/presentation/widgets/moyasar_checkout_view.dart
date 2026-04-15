import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moyasar/moyasar.dart';

import '../../../../core/constants/api_constants.dart';

PaymentConfig buildMoyasarPaymentConfig({
  required double amount,
  required String description,
  required Map<String, dynamic> metadata,
}) {
  return PaymentConfig(
    publishableApiKey: ApiConstants.moyasarPublishableKey,
    amount: (amount * 100).round(),
    currency: 'SAR',
    description: description,
    metadata: metadata,
    supportedNetworks: const [
      PaymentNetwork.visa,
      PaymentNetwork.mada,
      PaymentNetwork.masterCard,
    ],
    creditCard: CreditCardConfig(
      saveCard: false,
      manual: false,
    ),
    applePay: ApplePayConfig(
      merchantId: ApiConstants.moyasarApplePayMerchantId,
      label: ApiConstants.moyasarApplePayLabel,
      saveCard: false,
      manual: false,
    ),
  );
}

String extractMoyasarError(dynamic result, String fallbackMessage) {
  if (result is ApiError) return result.message;
  if (result is AuthError) return result.message;
  if (result is ValidationError) return result.message;
  if (result is PaymentCanceledError) return result.message;
  if (result is UnprocessableTokenError) return result.message;
  if (result is TimeoutError) return result.message;
  if (result is NetworkError) return result.message;
  if (result is UnspecifiedError) return result.message;
  return fallbackMessage;
}

class MoyasarCheckoutView extends StatelessWidget {
  const MoyasarCheckoutView({
    super.key,
    required this.config,
    required this.onPaymentResult,
    this.applePayTitle,
  });

  final PaymentConfig config;
  final void Function(dynamic result) onPaymentResult;
  final String? applePayTitle;

  bool get _canShowApplePay => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_canShowApplePay) ...[
            if (applePayTitle != null) ...[
              Text(
                applePayTitle!,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
            ],
            ApplePay(
              config: config,
              onPaymentResult: onPaymentResult,
            ),
            const SizedBox(height: 16),
            Text(
              'credit_card'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
          ],
          CreditCard(
            config: config,
            onPaymentResult: onPaymentResult,
            locale: context.locale.languageCode == 'ar'
                ? const Localization.ar()
                : const Localization.en(),
          ),
        ],
      ),
    );
  }
}
