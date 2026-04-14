// Event Request Card - Presentation Widget
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/event_request_entity.dart';
import 'event_request_status_badge.dart';

class EventRequestCard extends StatefulWidget {
  final EventRequestEntity request;
  final VoidCallback onTap;

  const EventRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  State<EventRequestCard> createState() => _EventRequestCardState();
}

class _EventRequestCardState extends State<EventRequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getEventTypeTranslation(String type) {
    switch (type) {
      case 'birthday':
        return 'event_type_birthday'.tr();
      case 'graduation':
        return 'event_type_graduation'.tr();
      case 'family':
        return 'event_type_family'.tr();
      case 'corporate':
        return 'event_type_corporate'.tr();
      case 'wedding':
        return 'event_type_wedding'.tr();
      case 'other':
        return 'event_type_other'.tr();
      default:
        return type;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'birthday':
        return Iconsax.cake;
      case 'graduation':
        return Iconsax.medal_star;
      case 'family':
        return Iconsax.home_2;
      case 'corporate':
        return Iconsax.briefcase;
      case 'wedding':
        return Iconsax.heart;
      default:
        return Iconsax.star;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'birthday':
        return AppColors.primaryPink;
      case 'graduation':
        return const Color(0xFF8B5CF6);
      case 'family':
        return const Color(0xFF06B6D4);
      case 'corporate':
        return const Color(0xFF3B82F6);
      case 'wedding':
        return const Color(0xFFEC4899);
      default:
        return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final dateFormat = DateFormat(
      'yyyy-MM-dd hh:mm a',
      context.locale.toString(),
    );
    final dateStr = dateFormat.format(widget.request.startTime.toLocal());
    final eventTypeColor = _getEventTypeColor(widget.request.type);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? eventTypeColor.withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
              width: _isPressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? eventTypeColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isPressed ? 16 : 12,
                offset: Offset(0, _isPressed ? 8 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Color accent bar at top
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [eventTypeColor, eventTypeColor.withOpacity(0.6)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Type & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event type icon with color background
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  eventTypeColor.withOpacity(0.15),
                                  eventTypeColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getEventTypeIcon(widget.request.type),
                              color: eventTypeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getEventTypeTranslation(widget.request.type),
                                  style: const TextStyle(
                                    fontFamily: 'MontserratArabic',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${widget.request.id.substring(0, 8)}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          EventRequestStatusBadge(
                            status: widget.request.status,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Info Grid
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Iconsax.calendar_1,
                                title: 'date_time'.tr(),
                                value: dateStr,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _InfoTile(
                                icon: Iconsax.clock,
                                title: 'duration'.tr(),
                                value: 'duration_hours_value'.tr(
                                  args: [
                                    widget.request.durationHours.toString(),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _InfoTile(
                                icon: Iconsax.people,
                                title: 'persons_count'.tr(),
                                value: 'persons_count_value'.tr(
                                  args: [widget.request.persons.toString()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price section (if quoted)
                      if (widget.request.quotedPrice != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.primaryOrange.withOpacity(0.08),
                                AppColors.primaryRed.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryOrange.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Iconsax.wallet_3,
                                      size: 16,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'quoted_price'.tr(),
                                    style: const TextStyle(
                                      fontFamily: 'MontserratArabic',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    widget.request.quotedPrice!.toStringAsFixed(
                                      0,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'MontserratArabic',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'currency'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'MontserratArabic',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryRed.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
