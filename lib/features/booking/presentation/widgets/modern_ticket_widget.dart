import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

/// Simple & Elegant Ticket Widget - Classic ticket design
class ModernTicketWidget extends StatelessWidget {
  final String ticketId;
  final String status; // valid | used | expired | cancelled
  final int personNumber;
  final int totalPersons;
  final String? holderName;
  final String? holderPhone;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final VoidCallback onViewQr;
  final VoidCallback? onCopyId;
  final VoidCallback? onShare;

  const ModernTicketWidget({
    super.key,
    required this.ticketId,
    required this.status,
    required this.personNumber,
    required this.totalPersons,
    this.holderName,
    this.holderPhone,
    this.validFrom,
    this.validUntil,
    this.createdAt,
    required this.onViewQr,
    this.onCopyId,
    this.onShare,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'valid':
        return const Color(0xFF22C55E);
      case 'used':
        return const Color(0xFF64748B);
      case 'expired':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel() {
    switch (status.toLowerCase()) {
      case 'valid':
        return 'valid'.tr();
      case 'used':
        return 'used'.tr();
      case 'expired':
        return 'expired'.tr();
      case 'cancelled':
        return 'cancelled'.tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onViewQr();
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Left Stub - QR Section
              _buildStubSection(context, statusColor, isDark),

              // Perforated Divider
              _buildPerforatedDivider(isDark),

              // Right Main Section
              _buildMainSection(context, statusColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStubSection(
    BuildContext context,
    Color statusColor,
    bool isDark,
  ) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withOpacity(0.85)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.scan_barcode5,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          // Person Number
          Text(
            '#$personNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'of_total_persons'.tr(args: [totalPersons.toString()]),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforatedDivider(bool isDark) {
    return SizedBox(
      width: 20,
      child: Stack(
        children: [
          // Background
          Container(color: isDark ? const Color(0xFF1F2937) : Colors.white),
          // Top Notch
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111827)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Bottom Notch
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111827)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Dashed Line
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                return Container(
                  width: 2,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(
    BuildContext context,
    Color statusColor,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row - Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.ticket5, size: 18, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      'ticket'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Middle - Ticket ID
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticketId.length > 20
                        ? '${ticketId.substring(0, 8)}...${ticketId.substring(ticketId.length - 8)}'
                        : ticketId,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onCopyId != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onCopyId!();
                    },
                    child: Icon(
                      Iconsax.copy,
                      size: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
              ],
            ),

            // Bottom Row - Date & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date Info
                if (validFrom != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(validFrom!),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(),

                // Action Buttons
                Row(
                  children: [
                    if (onShare != null) ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onShare!();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.share,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onViewQr();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.scan_barcode,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'QR',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ticket Clipper for skeleton loader
class TicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double cornerRadius;

  TicketClipper({this.notchRadius = 10, this.cornerRadius = 16});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;

    path.addRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
    );

    return path;
  }

  @override
  bool shouldReclip(TicketClipper oldClipper) => false;
}
