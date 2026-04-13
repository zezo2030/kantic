import 'package:flutter/material.dart';
import '../theme/gradients.dart';

/// A custom segmented toggle button with gradient background
/// Used for switching between Branches and Map views
class GradientSegmentedToggle extends StatefulWidget {
  final List<String> labels;
  final TabController controller;
  final double height;
  final double borderRadius;

  const GradientSegmentedToggle({
    super.key,
    required this.labels,
    required this.controller,
    this.height = 50,
    this.borderRadius = 30,
  });

  @override
  State<GradientSegmentedToggle> createState() =>
      _GradientSegmentedToggleState();
}

class _GradientSegmentedToggleState extends State<GradientSegmentedToggle> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: AppGradients.gradientMapBranches,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          widget.labels.length,
          (index) => Expanded(
            child: _buildSegment(index),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(int index) {
    final isSelected = widget.controller.index == index;

    return GestureDetector(
      onTap: () {
        widget.controller.animateTo(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          // Keep full-pill gradient; only lighten selected half
          color: isSelected ? Colors.white.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius - 6),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: isSelected ? 17 : 16,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.labels[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

