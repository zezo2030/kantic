import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../../domain/usecases/get_offer_booking_details_usecase.dart';
import '../../domain/usecases/get_offer_booking_tickets_usecase.dart';
import '../../data/models/offer_booking_model.dart';
import '../../data/models/offer_ticket_model.dart';
import 'offer_ticket_page.dart';

class OfferBookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const OfferBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<OfferBookingDetailsPage> createState() =>
      _OfferBookingDetailsPageState();
}

class _OfferBookingDetailsPageState extends State<OfferBookingDetailsPage> {
  OfferBookingModel? _booking;
  List<OfferTicketModel> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b =
          await sl<GetOfferBookingDetailsUseCase>()(widget.bookingId);
      final t =
          await sl<GetOfferBookingTicketsUseCase>()(widget.bookingId);
      setState(() {
        _booking = b;
        _tickets = t;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('offer_booking_details'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
          ? Center(child: Text('error'.tr()))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(_booking!.title),
                Text(
                  '${'total'.tr()}: ${_booking!.totalPrice}',
                ),
                Text('${'payment_status'.tr()}: ${_booking!.paymentStatus}'),
                const Divider(),
                Text('tickets'.tr()),
                ..._tickets.map(
                  (t) => ListTile(
                    title: Text(t.status),
                    subtitle: Text(t.ticketKind),
                    trailing: const Icon(Icons.qr_code),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OfferTicketPage(ticket: t),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
