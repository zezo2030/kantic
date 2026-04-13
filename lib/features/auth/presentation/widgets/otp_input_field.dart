import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:easy_localization/easy_localization.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final int length;
  final bool enabled;
  final String? errorText;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'otp_enter_code'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        PinCodeTextField(
          appContext: context,
          length: length,
          controller: controller,
          enabled: enabled,
          animationType: AnimationType.fade,
          animationDuration: const Duration(milliseconds: 300),
          enableActiveFill: true,
          keyboardType: TextInputType.number,
          onCompleted: onCompleted,
          onChanged: onChanged,
          beforeTextPaste: (text) {
            return text != null &&
                text.length == length &&
                RegExp(r'^\d+$').hasMatch(text);
          },
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 56,
            fieldWidth: 48,
            activeFillColor: theme.colorScheme.surface,
            inactiveFillColor: theme.colorScheme.surfaceContainerHighest,
            selectedFillColor: theme.colorScheme.primaryContainer,
            activeColor: theme.primaryColor,
            inactiveColor: theme.colorScheme.outline,
            selectedColor: theme.primaryColor,
            disabledColor: theme.colorScheme.outline.withValues(alpha: 0.5),
            borderWidth: 1.5,
          ),
          textStyle: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
