import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSwitcher extends StatelessWidget {
  final String? currentLanguage;
  final void Function(String)? onLanguageChanged;

  const LanguageSwitcher({
    super.key,
    this.currentLanguage,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = currentLanguage ?? context.locale.languageCode;

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(
            currentLocale.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      onSelected: (String language) {
        if (onLanguageChanged != null) {
          onLanguageChanged!(language);
        } else {
          context.setLocale(Locale(language));
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'ar',
          child: Row(
            children: [
              Text('🇸🇦', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('arabic'.tr()),
              if (currentLocale == 'ar') ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Text('🇺🇸', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('english'.tr()),
              if (currentLocale == 'en') ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class LanguageSwitcherButton extends StatelessWidget {
  final String? currentLanguage;
  final void Function(String)? onLanguageChanged;

  const LanguageSwitcherButton({
    super.key,
    this.currentLanguage,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = currentLanguage ?? context.locale.languageCode;

    return OutlinedButton.icon(
      onPressed: () {
        final newLanguage = currentLocale == 'ar' ? 'en' : 'ar';
        if (onLanguageChanged != null) {
          onLanguageChanged!(newLanguage);
        } else {
          context.setLocale(Locale(newLanguage));
        }
      },
      icon: Icon(Icons.language, size: 18),
      label: Text(
        currentLocale == 'ar'
            ? 'language_english'.tr()
            : 'language_arabic'.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
