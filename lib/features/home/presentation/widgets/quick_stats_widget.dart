import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class QuickStatsWidget extends StatefulWidget {
  final int customersCount;
  final int eventsCount;
  final int branchesCount;

  const QuickStatsWidget({
    super.key,
    required this.customersCount,
    required this.eventsCount,
    required this.branchesCount,
  });

  @override
  State<QuickStatsWidget> createState() => _QuickStatsWidgetState();
}

class _QuickStatsWidgetState extends State<QuickStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _counterControllers;
  late List<Animation<double>> _counterAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _counterControllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 1500 + (index * 200)),
        vsync: this,
      );
    });

    _counterAnimations = _counterControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    _animationController.forward();

    // Start counter animations with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      for (var controller in _counterControllers) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _counterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          _buildSectionTitle(),

          const SizedBox(height: 16),

          // Stats Cards
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.luxuryGoldGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.luxuryGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.analytics, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quick_stats'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.luxuryTextPrimary,
              ),
            ),
            Text(
              'at_a_glance'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.luxuryTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'icon': Icons.people,
        'title': 'customers_count'.tr(),
        'value': widget.customersCount,
        'color': AppColors.successColor,
        'gradient': LinearGradient(
          colors: [
            AppColors.successColor,
            AppColors.successColor.withOpacity(0.8),
          ],
        ),
      },
      {
        'icon': Icons.event,
        'title': 'events_count'.tr(),
        'value': widget.eventsCount,
        'color': AppColors.infoColor,
        'gradient': LinearGradient(
          colors: [AppColors.infoColor, AppColors.infoColor.withOpacity(0.8)],
        ),
      },
      {
        'icon': Icons.location_on,
        'title': 'branches_count'.tr(),
        'value': widget.branchesCount,
        'color': AppColors.warningColor,
        'gradient': LinearGradient(
          colors: [
            AppColors.warningColor,
            AppColors.warningColor.withOpacity(0.8),
          ],
        ),
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: AnimatedBuilder(
            animation: _counterAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _counterAnimations[index].value),
                child: Opacity(
                  opacity: _counterAnimations[index].value,
                  child: _buildStatCard(
                    icon: stat['icon'] as IconData,
                    title: stat['title'] as String,
                    value: stat['value'] as int,
                    gradient: stat['gradient'] as LinearGradient,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int value,
    required LinearGradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),

          const SizedBox(height: 12),

          // Animated Counter
          AnimatedBuilder(
            animation: _counterAnimations[_getStatIndex(icon)],
            builder: (context, child) {
              final animatedValue =
                  (value * _counterAnimations[_getStatIndex(icon)].value)
                      .round();
              return Text(
                _formatNumber(animatedValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // Title
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  int _getStatIndex(IconData icon) {
    if (icon == Icons.people) return 0;
    if (icon == Icons.event) return 1;
    if (icon == Icons.location_on) return 2;
    return 0;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
