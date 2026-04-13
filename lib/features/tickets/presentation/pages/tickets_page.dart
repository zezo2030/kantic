import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/tickets_remote_datasource.dart';
import '../../data/models/ticket_model.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/share_utils.dart';

class TicketsPage extends StatefulWidget {
  final String bookingId;
  final String bookingStatus;

  const TicketsPage({
    super.key,
    required this.bookingId,
    required this.bookingStatus,
  });

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  late final TicketsRemoteDataSource ds = TicketsRemoteDataSourceImpl(
    dio: DioClient.instance,
  );
  late Future<List<TicketModel>> ticketsFuture;

  @override
  void initState() {
    super.initState();
    ticketsFuture = ds.getBookingTickets(widget.bookingId);
  }

  String _localizedTicketStatus(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return 'valid'.tr();
      case 'used':
        return 'used'.tr();
      case 'expired':
        return 'expired'.tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingStatus.toLowerCase() != 'confirmed') {
      return Scaffold(
        appBar: AppBar(title: Text('booking_details'.tr())),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('complete_payment_to_view_tickets'.tr()),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('booking_details'.tr())),
      body: FutureBuilder<List<TicketModel>>(
        future: ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final tickets = snapshot.data ?? const <TicketModel>[];
          if (tickets.isEmpty) {
            return Center(child: Text('no_tickets'.tr()));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = tickets[index];
              return Card(
                child: ListTile(
                  title: Text(
                    '#${t.id.substring(0, 8)} • ${_localizedTicketStatus(t.status)}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.validFrom != null && t.validUntil != null)
                        Text(
                          '${DateFormat('yyyy-MM-dd HH:mm').format(t.validFrom!)} → ${DateFormat('HH:mm').format(t.validUntil!)}',
                        ),
                      if (t.holderName != null) Text(t.holderName!),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final qr = await ds.getTicketQr(t.id);
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('qr_code'.tr()),
                                  const SizedBox(height: 12),
                                  if (qr.startsWith('data:image'))
                                    Image.memory(
                                      base64Decode(qr.split(',').last),
                                    )
                                  else
                                    SelectableText(qr),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: t.id),
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('copied'.tr()),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy),
                                        label: Text('copy_ticket_id'.tr()),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          try {
                                            HapticFeedback.selectionClick();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('share'.tr()),
                                              ),
                                            );
                                            await shareTicketQrPreferWhatsApp(
                                              context: context,
                                              ticketId: t.id,
                                              qrData: qr,
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'unknown_error'.tr(),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.share),
                                        label: Text('share'.tr()),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text('view_details'.tr()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
