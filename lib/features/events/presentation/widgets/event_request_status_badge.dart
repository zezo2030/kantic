// Event Request Status Badge - Presentation Widget
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/event_request_status.dart';

class EventRequestStatusBadge extends StatelessWidget {
  final EventRequestStatus status;
  final bool compact;

  const EventRequestStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  _StatusConfig get _config {
    switch (status) {
      case EventRequestStatus.draft:
        return _StatusConfig(
          background: const Color(0xFFF1F5F9),
          foreground: const Color(0xFF64748B),
          icon: Icons.circle,
          label: 'draft'.tr(),
        );
      case EventRequestStatus.submitted:
        return _StatusConfig(
          background: const Color(0xFFE0E7FF),
          foreground: const Color(0xFF4338CA),
          icon: Icons.arrow_upward_rounded,
          label: 'submitted'.tr(),
        );
      case EventRequestStatus.underReview:
        return _StatusConfig(
          background: const Color(0xFFFEF9C3),
          foreground: const Color(0xFF854D0E),
          icon: Icons.visibility_rounded,
          label: 'under_review'.tr(),
        );
      case EventRequestStatus.quoted:
        return _StatusConfig(
          background: const Color(0xFFF3E8FF),
          foreground: const Color(0xFF7E22CE),
          icon: Icons.request_quote_rounded,
          label: 'quoted'.tr(),
        );
      case EventRequestStatus.invoiced:
        return _StatusConfig(
          background: const Color(0xFFCFFAFE),
          foreground: const Color(0xFF0E7490),
          icon: Icons.receipt_long_rounded,
          label: 'invoiced'.tr(),
        );
      case EventRequestStatus.depositPaid:
        return _StatusConfig(
          background: const Color(0xFFFEF3C7),
          foreground: const Color(0xFFB45309),
          icon: Icons.payments_rounded,
          label: 'status_deposit_paid'.tr(),
        );
      case EventRequestStatus.paid:
        return _StatusConfig(
          background: const Color(0xFFDCFCE7),
          foreground: const Color(0xFF15803D),
          icon: Icons.check_circle_rounded,
          label: 'paid'.tr(),
        );
      case EventRequestStatus.confirmed:
        return _StatusConfig(
          background: const Color(0xFFDCFCE7),
          foreground: const Color(0xFF15803D),
          icon: Icons.event_available_rounded,
          label: 'confirmed'.tr(),
        );
      case EventRequestStatus.rejected:
        return _StatusConfig(
          background: const Color(0xFFFEE2E2),
          foreground: const Color(0xFFB91C1C),
          icon: Icons.cancel_rounded,
          label: 'rejected'.tr(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 10, color: config.foreground),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                color: config.foreground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'MontserratArabic',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: config.foreground.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(
              color: config.foreground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: config.foreground.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.foreground,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'MontserratArabic',
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
  });
}
