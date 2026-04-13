// Event Request Status Badge - Presentation Widget
import 'package:flutter/material.dart';
import '../../domain/entities/event_request_status.dart';

class EventRequestStatusBadge extends StatelessWidget {
  final EventRequestStatus status;

  const EventRequestStatusBadge({super.key, required this.status});

  _StatusColors get _statusColors {
    switch (status) {
      case EventRequestStatus.draft:
        return const _StatusColors(
          background: Color(0xFFF1F5F9), // slate-100
          foreground: Color(0xFF475569), // slate-600
        );
      case EventRequestStatus.submitted:
        return const _StatusColors(
          background: Color(0xFFE0E7FF), // indigo-100
          foreground: Color(0xFF4338CA), // indigo-700
        );
      case EventRequestStatus.underReview:
        return const _StatusColors(
          background: Color(0xFFFEF08A), // yellow-200
          foreground: Color(0xFFA16207), // yellow-800
        );
      case EventRequestStatus.quoted:
        return const _StatusColors(
          background: Color(0xFFF3E8FF), // purple-100
          foreground: Color(0xFF7E22CE), // purple-700
        );
      case EventRequestStatus.invoiced:
        return const _StatusColors(
          background: Color(0xFFCFFAFE), // cyan-100
          foreground: Color(0xFF0E7490), // cyan-700
        );
      case EventRequestStatus.paid:
      case EventRequestStatus.confirmed:
        return const _StatusColors(
          background: Color(0xFFDCFCE7), // green-100
          foreground: Color(0xFF15803D), // green-700
        );
      case EventRequestStatus.rejected:
        return const _StatusColors(
          background: Color(0xFFFEE2E2), // red-100
          foreground: Color(0xFFB91C1C), // red-700
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors;
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
            status.getDisplayName(),
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
}

class _StatusColors {
  final Color background;
  final Color foreground;

  const _StatusColors({required this.background, required this.foreground});
}
