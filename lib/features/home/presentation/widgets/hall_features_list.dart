import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

class HallFeaturesList extends StatelessWidget {
  final List<String> features;

  const HallFeaturesList({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.star_1,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'hall_features'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Features grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFeatureIcon(feature),
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    final featureLower = feature.toLowerCase();

    if (featureLower.contains('sound') || featureLower.contains('audio')) {
      return Iconsax.volume_high;
    } else if (featureLower.contains('projector') ||
        featureLower.contains('screen')) {
      return Iconsax.video;
    } else if (featureLower.contains('air') ||
        featureLower.contains('conditioning')) {
      return Iconsax.wind;
    } else if (featureLower.contains('stage') ||
        featureLower.contains('platform')) {
      return Iconsax.microphone;
    } else if (featureLower.contains('lighting') ||
        featureLower.contains('light')) {
      return Iconsax.lamp;
    } else if (featureLower.contains('wifi') ||
        featureLower.contains('internet')) {
      return Iconsax.wifi;
    } else if (featureLower.contains('parking')) {
      return Iconsax.car;
    } else if (featureLower.contains('security')) {
      return Iconsax.security_safe;
    } else if (featureLower.contains('catering') ||
        featureLower.contains('food')) {
      return Iconsax.cake;
    } else if (featureLower.contains('decoration') ||
        featureLower.contains('decor')) {
      return Iconsax.paintbucket;
    } else {
      return Iconsax.tick_circle;
    }
  }
}
