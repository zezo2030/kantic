import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/offer_ticket_model.dart';

class OfferTicketPage extends StatelessWidget {
  final OfferTicketModel ticket;

  const OfferTicketPage({super.key, required this.ticket});

  Color _getStatusColor() {
    switch (ticket.status.toLowerCase()) {
      case 'valid':
      case 'active':
        return AppColors.successColor;
      case 'used':
      case 'scanned':
        return const Color(0xFF3B82F6);
      case 'expired':
        return AppColors.errorColor;
      default:
        return AppColors.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ticket.qrData ?? '';
    final statusColor = _getStatusColor();
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'ar');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'offer_ticket'.tr(),
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7B2FF7), Color(0xFF312E81)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.ticket_star,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ticket.ticketKind.tr(),
                          style: TextStyle(
                            fontFamily: 'MontserratArabic',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            ticket.status.tr(),
                            style: TextStyle(
                              fontFamily: 'MontserratArabic',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // QR Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (data.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B2FF7)
                                      .withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: data,
                              version: QrVersions.auto,
                              size: 220,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.warningColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.warningColor
                                      .withOpacity(0.15)),
                            ),
                            child: Row(
                              children: [
                                Icon(Iconsax.warning_2,
                                    size: 18,
                                    color: AppColors.warningColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'do_not_share_qr_warning'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'MontserratArabic',
                                      fontSize: 12,
                                      color: AppColors.warningColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                const Icon(Iconsax.scan_barcode,
                                    size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  'qr_not_ready'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'MontserratArabic',
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Ticket Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Iconsax.ticket,
                    label: 'type'.tr(),
                    value: ticket.ticketKind.tr(),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Iconsax.status,
                    label: 'status'.tr(),
                    value: ticket.status.tr(),
                    valueColor: statusColor,
                  ),
                  if (ticket.scannedAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Iconsax.scan,
                      label: 'scanned_at'.tr(),
                      value: dateFormat.format(ticket.scannedAt!),
                    ),
                  ],
                  if (ticket.expiresAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Iconsax.timer_1,
                      label: 'expires_at'.tr(),
                      value: dateFormat.format(ticket.expiresAt!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Iconsax.hashtag,
                          size: 16, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.id,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Clipboard.setData(
                              ClipboardData(text: ticket.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('id_copied'.tr())),
                          );
                        },
                        child: const Icon(Iconsax.copy,
                            size: 16, color: AppColors.primaryRed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7B2FF7)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
