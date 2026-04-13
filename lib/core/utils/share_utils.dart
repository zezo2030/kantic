import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> shareTicketQrPreferWhatsApp({
  required BuildContext context,
  required String ticketId,
  required String qrData,
}) async {
  final String text =
      '${tr('ticket')}: $ticketId${qrData.startsWith('data:image') ? '' : '\nQR: $qrData'}';
  final Uri whatsappUri = Uri.parse(
    'whatsapp://send?text=${Uri.encodeComponent(text)}',
  );
  try {
    if (!qrData.startsWith('data:image') && await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (qrData.startsWith('data:image')) {
      final String payload = qrData.split(',').last;
      final List<int> bytes = base64Decode(payload);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/ticket-$ticketId-qr.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([
        XFile(
          file.path,
          mimeType: 'image/png',
          name: 'ticket-$ticketId-qr.png',
        ),
      ], text: '${tr('ticket')}: $ticketId');
    } else {
      await Share.share(text);
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('error_occurred'))),
    );
  }
}
