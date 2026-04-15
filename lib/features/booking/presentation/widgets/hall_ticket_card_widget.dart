import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/booking_model.dart';
import '../../../../core/theme/app_colors.dart';

class HallTicketCardWidget extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onViewQr;
  final VoidCallback? onCopyId;

  const HallTicketCardWidget({
    super.key,
    required this.booking,
    required this.onViewQr,
    this.onCopyId,
  });

  Color _statusColor() {
    final s = booking.displayTicketStatus.toLowerCase();
    final daysLeft = booking.displayValidUntil.difference(DateTime.now()).inDays;
    if (daysLeft < 0 || s == 'used' || s == 'expired') {
      return AppColors.errorColor;
    }
    switch (s) {
      case 'valid':
      case 'confirmed':
      case 'active':
      case 'completed':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      case 'pending':
        return AppColors.warningColor;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel() {
    final s = booking.displayTicketStatus.toLowerCase();
    final daysLeft = booking.displayValidUntil.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'expired'.tr();
    if (s == 'used') return 'ticket_used'.tr();
    if (s == 'valid' || s == 'confirmed') return 'active'.tr();
    return s.tr();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor();
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');
    final lang = context.locale.languageCode;
    final title = booking.branchDisplayName(lang);
    final gradientColors = [
      const Color(0xFF1E3A8A),
      const Color(0xFF312E81),
    ];
    final daysLeft = booking.displayValidUntil.difference(DateTime.now()).inDays;
    final stubIcon =
        booking.isLoyaltyHallTicket ? Iconsax.star : Iconsax.gift;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onViewQr();
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              _buildStubSection(gradientColors, daysLeft, stubIcon),
              _buildPerforatedDivider(isDark),
              Expanded(
                child: _buildMainSection(
                  context,
                  title,
                  statusColor,
                  isDark,
                  dateFormat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStubSection(
    List<Color> gradientColors,
    int daysLeft,
    IconData stubIcon,
  ) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(stubIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            daysLeft > 0 ? '$daysLeft' : '0',
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'days_left'.tr(),
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
          Container(color: isDark ? const Color(0xFF1F2937) : Colors.white),
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                return Container(
                  width: 2,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
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
    String title,
    Color statusColor,
    bool isDark,
    DateFormat dateFormat,
  ) {
    final chip = booking.isLoyaltyHallTicket
        ? 'my_hall_ticket_loyalty'.tr()
        : 'my_hall_ticket_complimentary'.tr();
    final copyId = booking.primaryTicketId.isNotEmpty
        ? booking.primaryTicketId
        : booking.id;
    final shortLen = copyId.length > 8 ? 8 : copyId.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontFamily: 'MontserratArabic',
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'start_date'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(booking.startTime),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                  width: 1, height: 20, color: Colors.grey.withOpacity(0.3)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'end_date'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(booking.displayValidUntil),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#${copyId.substring(0, shortLen)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.textHint,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onCopyId != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onCopyId!();
                      },
                      child: const Icon(
                        Iconsax.copy,
                        size: 16,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onViewQr();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.scan_barcode,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'QR',
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
