import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../data/models/subscription_purchase_model.dart';
import '../../../../core/theme/app_colors.dart';

class SubscriptionTicketWidget extends StatelessWidget {
  final SubscriptionPurchaseModel purchase;
  final VoidCallback onViewQr;
  final VoidCallback? onCopyId;

  const SubscriptionTicketWidget({
    super.key,
    required this.purchase,
    required this.onViewQr,
    this.onCopyId,
  });

  Color _getStatusColor() {
    final status = purchase.status.toLowerCase();
    final daysLeft = purchase.endsAt.difference(DateTime.now()).inDays;
    final isExpired = daysLeft <= 0;

    if (isExpired) return AppColors.errorColor;
    switch (status) {
      case 'active':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      case 'pending':
        return AppColors.warningColor;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel() {
    final status = purchase.status.toLowerCase();
    final daysLeft = purchase.endsAt.difference(DateTime.now()).inDays;
    final isExpired = daysLeft <= 0;

    if (isExpired) return 'expired'.tr();
    return status == 'active' ? 'active'.tr() : status.tr();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    // Gradient colors for subscription ticket (Elegant dark blue/purple or Gold)
    // We'll use a premium looking gradient
    final gradientColors = [
      const Color(0xFF1E3A8A), // Deep Blue
      const Color(0xFF312E81), // Indigo
    ];

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
              // Left Stub
              _buildStubSection(context, gradientColors),

              // Perforated Divider
              _buildPerforatedDivider(isDark),

              // Right Main Section
              _buildMainSection(context, statusColor, isDark, dateFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStubSection(BuildContext context, List<Color> gradientColors) {
    final daysLeft = purchase.endsAt.difference(DateTime.now()).inDays;

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
            child: const Icon(Iconsax.crown, color: Colors.white, size: 28),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // matches background of page
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
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
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
    Color statusColor,
    bool isDark,
    DateFormat dateFormat,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    purchase.planTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                      fontFamily: 'MontserratArabic',
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            // Middle - Dates
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
                        dateFormat.format(purchase.startedAt),
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
                  width: 1,
                  height: 20,
                  color: Colors.grey.withOpacity(0.3),
                ),
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
                        dateFormat.format(purchase.endsAt),
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

            // Bottom Row - ID & QR Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#${purchase.id.substring(0, purchase.id.length > 8 ? 8 : purchase.id.length)}',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A), // Match the stub gradient
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
                        const Icon(
                          Iconsax.scan_barcode,
                          size: 14,
                          color: Colors.white,
                        ),
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
      ),
    );
  }
}
