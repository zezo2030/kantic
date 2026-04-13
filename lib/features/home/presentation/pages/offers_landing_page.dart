import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/routes/app_route_generator.dart';

/// نقطة دخول لمسار `/offers` من الإشعارات (عروض الخصم على الحجز).
class OffersLandingPage extends StatelessWidget {
  const OffersLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('all_offers_page_title'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'offers_landing_hint'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.main,
                  (r) => false,
                ),
                child: Text('back_to_home'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
