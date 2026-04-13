import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

class MapPreviewWidget extends StatelessWidget {
  final double? lat;
  final double? lng;
  final VoidCallback? onOpenMaps;

  const MapPreviewWidget({super.key, this.lat, this.lng, this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    if (lat == null || lng == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        color: Colors.grey.shade200,
        child: Stack(
          children: [
            Center(
              child: Icon(Iconsax.map_1, size: 48, color: Colors.grey.shade500),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: onOpenMaps,
                icon: const Icon(Iconsax.location),
                label: Text('view_on_map'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
