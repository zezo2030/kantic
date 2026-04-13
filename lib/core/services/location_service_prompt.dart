import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';

bool _isLocationDialogOpen = false;

Future<void> promptEnableLocationServiceIfDisabled(BuildContext context) async {
  final isEnabled = await Geolocator.isLocationServiceEnabled();
  if (isEnabled || !context.mounted || _isLocationDialogOpen) return;

  _isLocationDialogOpen = true;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('enable_location_service'.tr()),
        content: Text('location_service_disabled_enable_to_continue'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('later'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text('enable_now'.tr()),
          ),
        ],
      );
    },
  );

  _isLocationDialogOpen = false;
}
