import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class PriceTagWidget extends StatelessWidget {
  final double price;
  final String? currency;
  final bool showDiscount;
  final double? originalPrice;
  final double? discountPercentage;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const PriceTagWidget({
    super.key,
    required this.price,
    this.currency,
    this.showDiscount = false,
    this.originalPrice,
    this.discountPercentage,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCurrency = currency ?? 'riyal'.tr();
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primaryRed;
    final effectiveTextColor = textColor ?? Colors.white;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: effectiveBackgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDiscount && originalPrice != null) ...[
            Text(
              '${originalPrice!.toStringAsFixed(0)} $effectiveCurrency',
              style: TextStyle(
                color: effectiveTextColor.withValues(alpha: 0.7),
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Text(
            '${price.toStringAsFixed(0)} $effectiveCurrency',
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (showDiscount && discountPercentage != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${discountPercentage!.toStringAsFixed(0)}% off',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PriceDisplayWidget extends StatelessWidget {
  final double price;
  final String? currency;
  final String? label;
  final TextStyle? priceStyle;
  final TextStyle? labelStyle;
  final CrossAxisAlignment alignment;

  const PriceDisplayWidget({
    super.key,
    required this.price,
    this.currency,
    this.label,
    this.priceStyle,
    this.labelStyle,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCurrency = currency ?? 'riyal'.tr();
    final effectivePriceStyle =
        priceStyle ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        );
    final effectiveLabelStyle =
        labelStyle ??
        const TextStyle(fontSize: 12, color: AppColors.textSecondary);

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: effectiveLabelStyle),
          const SizedBox(height: 2),
        ],
        Text(
          '${price.toStringAsFixed(0)} $effectiveCurrency',
          style: effectivePriceStyle,
        ),
      ],
    );
  }
}
