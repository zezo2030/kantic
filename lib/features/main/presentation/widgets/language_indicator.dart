import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class LanguageIndicator extends StatelessWidget {
  const LanguageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isArabic = currentLocale.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isArabic
            ? AppColors.arabicColor.withOpacity(0.1)
            : AppColors.englishColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isArabic ? AppColors.arabicColor : AppColors.englishColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isArabic ? Icons.language : Icons.translate,
            size: 16,
            color: isArabic ? AppColors.arabicColor : AppColors.englishColor,
          ),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'language_arabic'.tr() : 'language_english'.tr(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isArabic ? AppColors.arabicColor : AppColors.englishColor,
            ),
          ),
        ],
      ),
    );
  }
}
