import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/trip_request_status.dart';

class TripStatusChip extends StatelessWidget {
  const TripStatusChip({super.key, required this.status});

  final TripRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: colors.foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'MontserratArabic',
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _statusColors(BuildContext context, TripRequestStatus status) {
    switch (status) {
      case TripRequestStatus.pending:
        return const _StatusColors(
          background: Color(0xFFFEF08A), // yellow-200
          foreground: Color(0xFFA16207), // yellow-800
        );
      case TripRequestStatus.underReview:
        return const _StatusColors(
          background: Color(0xFFE0E7FF), // indigo-100
          foreground: Color(0xFF4338CA), // indigo-700
        );
      case TripRequestStatus.approved:
        return const _StatusColors(
          background: Color(0xFFD1FAE5), // emerald-100
          foreground: Color(0xFF047857), // emerald-700
        );
      case TripRequestStatus.rejected:
      case TripRequestStatus.cancelled:
        return const _StatusColors(
          background: Color(0xFFFEE2E2), // red-100
          foreground: Color(0xFFB91C1C), // red-700
        );
      case TripRequestStatus.invoiced:
        return const _StatusColors(
          background: Color(0xFFCFFAFE), // cyan-100
          foreground: Color(0xFF0E7490), // cyan-700
        );
      case TripRequestStatus.paid:
        return const _StatusColors(
          background: Color(0xFFDCFCE7), // green-100
          foreground: Color(0xFF15803D), // green-700
        );
      case TripRequestStatus.completed:
        return const _StatusColors(
          background: Color(0xFFF3E8FF), // purple-100
          foreground: Color(0xFF7E22CE), // purple-700
        );
      case TripRequestStatus.unknown:
        return const _StatusColors(
          background: Color(0xFFF1F5F9), // slate-100
          foreground: Color(0xFF475569), // slate-600
        );
    }
  }

  String _statusLabel(TripRequestStatus status) {
    switch (status) {
      case TripRequestStatus.pending:
        return tr('status_pending');
      case TripRequestStatus.underReview:
        return tr('status_under_review');
      case TripRequestStatus.approved:
        return tr('status_approved');
      case TripRequestStatus.rejected:
        return tr('status_rejected');
      case TripRequestStatus.invoiced:
        return tr('status_invoiced');
      case TripRequestStatus.paid:
        return tr('status_paid');
      case TripRequestStatus.completed:
        return tr('status_completed');
      case TripRequestStatus.cancelled:
        return tr('status_cancelled');
      case TripRequestStatus.unknown:
        return tr('status_unknown');
    }
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
