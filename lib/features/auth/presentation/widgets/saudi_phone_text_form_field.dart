import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class SaudiPhoneTextFormField extends StatelessWidget {
  const SaudiPhoneTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.leadingPhoneIcon = false,
    this.textInputAction,
    this.focusNode,
    this.nextFocus,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool leadingPhoneIcon;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;

  static const Color _border = Color(0xFFE8DDD4);
  static const Color _hint = Color(0xFFC0C0C0);

  @override
  Widget build(BuildContext context) {
    final double prefixMinWidth = leadingPhoneIcon ? 148 : 108;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        textInputAction: textInputAction ?? TextInputAction.next,
        onFieldSubmitted: (_) => nextFocus?.requestFocus(),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
          fontFamily: 'MontserratArabic',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _hint,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'MontserratArabic',
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsetsDirectional.only(
            start: 4,
            end: 16,
            top: 16,
            bottom: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (leadingPhoneIcon) ...<Widget>[
                    Icon(
                      Icons.phone_android_outlined,
                      size: 22,
                      color: const Color(0xB3FF5E00),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '+966',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                        fontFamily: 'MontserratArabic',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 1, height: 24, color: _border),
                ],
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: prefixMinWidth,
            maxHeight: 56,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primaryRed,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.errorColor,
              width: 1.5,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
