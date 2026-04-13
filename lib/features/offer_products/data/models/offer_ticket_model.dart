import '../../../../core/utils/api_json.dart';
import '../../domain/entities/offer_ticket_entity.dart';

class OfferTicketModel extends OfferTicketEntity {
  const OfferTicketModel({
    required super.id,
    required super.offerBookingId,
    required super.ticketKind,
    required super.status,
    super.startedAt,
    super.expiresAt,
    super.scannedAt,
    super.qrData,
  });

  factory OfferTicketModel.fromJson(Map<String, dynamic> json) {
    final meta = asJsonMap(json['metadata']);
    final qrFromMeta = meta['qrData']?.toString();
    return OfferTicketModel(
      id: json['id']?.toString() ?? '',
      offerBookingId: json['offerBookingId']?.toString() ?? '',
      ticketKind: json['ticketKind']?.toString() ?? 'standard',
      status: json['status']?.toString() ?? 'valid',
      startedAt: parseDate(json['startedAt']),
      expiresAt: parseDate(json['expiresAt']),
      scannedAt: parseDate(json['scannedAt']),
      qrData: json['qrData']?.toString() ?? qrFromMeta,
    );
  }
}
