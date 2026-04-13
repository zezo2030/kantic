import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/offer_ticket_model.dart';

class OfferTicketPage extends StatelessWidget {
  final OfferTicketModel ticket;

  const OfferTicketPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final data = ticket.qrData ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('offer_ticket'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('${'status'.tr()}: ${ticket.status}'),
            Text('${'type'.tr()}: ${ticket.ticketKind}'),
            const SizedBox(height: 24),
            if (data.isNotEmpty)
              QrImageView(data: data, size: 220)
            else
              Text('qr_not_ready'.tr()),
            const SizedBox(height: 16),
            Text(
              'do_not_share_qr_warning'.tr(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
