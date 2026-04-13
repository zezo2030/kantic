import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/branch_entity.dart';
import '../../../../core/theme/app_colors.dart';

class WorkingHoursWidget extends StatefulWidget {
  final BranchEntity branch;

  const WorkingHoursWidget({super.key, required this.branch});

  @override
  State<WorkingHoursWidget> createState() => _WorkingHoursWidgetState();
}

class _WorkingHoursWidgetState extends State<WorkingHoursWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branch.workingHours == null ||
        widget.branch.workingHours!.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildExpandableHeader(context),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildWorkingHoursList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(context, showExpandButton: false),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'working_schedule'.tr(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'working_hours'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentDayStatus(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status indicator
              _buildStatusIndicator(context),
              const SizedBox(width: 12),
              // Expand/Collapse icon
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool showExpandButton}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'working_hours'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCurrentDayStatus(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (showExpandButton) ...[
            const SizedBox(width: 12),
            _buildStatusIndicator(context),
            const SizedBox(width: 12),
            Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final currentDay = DateTime.now().weekday - 1;
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayKey = days[currentDay];
    final todayHours = widget.branch.workingHours![todayKey];
    final isOpen = todayHours != null && todayHours.toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.availableColor.withValues(alpha: 0.1)
            : AppColors.closedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen
              ? AppColors.availableColor.withValues(alpha: 0.3)
              : AppColors.closedColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.availableColor : AppColors.closedColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'open'.tr() : 'closed'.tr(),
            style: TextStyle(
              color: isOpen ? AppColors.availableColor : AppColors.closedColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursList(BuildContext context) {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final currentDay = DateTime.now().weekday - 1;

    return Column(
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final dayKey = entry.value;
        final dayName = _getDayName(dayKey);
        final hours = widget.branch.workingHours![dayKey];
        final isOpen = hours != null && hours.toString().isNotEmpty;
        final isToday = index == currentDay;

        return Column(
          children: [
            _buildDayItem(
              context: context,
              dayName: dayName,
              hours: hours?.toString() ?? '',
              isOpen: isOpen,
              isToday: isToday,
              dayIcon: _getDayIcon(index),
            ),
            if (index < days.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.grey[200],
                indent: 20,
                endIndent: 20,
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDayItem({
    required BuildContext context,
    required String dayName,
    required String hours,
    required bool isOpen,
    required bool isToday,
    required IconData dayIcon,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isToday ? 8 : 0,
        vertical: isToday ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: isToday ? BorderRadius.circular(12) : null,
        border: isToday
            ? Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // يمكن إضافة تفاعل هنا لاحقاً
          },
          borderRadius: isToday ? BorderRadius.circular(12) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // أيقونة اليوم
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    dayIcon,
                    color: isOpen ? Colors.green[600] : Colors.grey[400],
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // اسم اليوم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isToday
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[800],
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'today'.tr(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOpen ? hours : 'closed_now'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isOpen
                              ? AppColors.availableColor
                              : AppColors.closedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge الحالة المحسّن
                _buildEnhancedStatusBadge(isOpen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [
                  AppColors.availableColor.withValues(alpha: 0.8),
                  AppColors.availableColor,
                ]
              : [
                  AppColors.closedColor.withValues(alpha: 0.8),
                  AppColors.closedColor,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? AppColors.availableColor : AppColors.closedColor)
                .withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'open'.tr() : 'closed'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(String dayKey) {
    switch (dayKey.toLowerCase()) {
      case 'monday':
        return 'monday'.tr();
      case 'tuesday':
        return 'tuesday'.tr();
      case 'wednesday':
        return 'wednesday'.tr();
      case 'thursday':
        return 'thursday'.tr();
      case 'friday':
        return 'friday'.tr();
      case 'saturday':
        return 'saturday'.tr();
      case 'sunday':
        return 'sunday'.tr();
      default:
        return dayKey;
    }
  }

  IconData _getDayIcon(int dayIndex) {
    switch (dayIndex) {
      case 0: // Monday
        return Icons.looks_one;
      case 1: // Tuesday
        return Icons.looks_two;
      case 2: // Wednesday
        return Icons.looks_3;
      case 3: // Thursday
        return Icons.looks_4;
      case 4: // Friday
        return Icons.looks_5;
      case 5: // Saturday
        return Icons.looks_6;
      case 6: // Sunday
        return Icons.looks_one;
      default:
        return Icons.calendar_today;
    }
  }

  String _getCurrentDayStatus() {
    if (widget.branch.workingHours == null ||
        widget.branch.workingHours!.isEmpty) {
      return 'working_schedule'.tr();
    }

    final currentDay = DateTime.now().weekday - 1;
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayKey = days[currentDay];
    final todayHours = widget.branch.workingHours![todayKey];

    if (todayHours != null && todayHours.toString().isNotEmpty) {
      return '${'open_now'.tr()} - ${todayHours.toString()}';
    } else {
      return 'closed_now'.tr();
    }
  }
}
