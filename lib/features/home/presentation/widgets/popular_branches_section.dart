import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/branch_entity.dart';
import 'popular_branch_card.dart';
import '../../../../core/theme/app_colors.dart';

class PopularBranchesSection extends StatefulWidget {
  final List<BranchEntity> branches;
  final VoidCallback? onViewAll;

  const PopularBranchesSection({
    super.key,
    required this.branches,
    this.onViewAll,
  });

  @override
  State<PopularBranchesSection> createState() => _PopularBranchesSectionState();
}

class _PopularBranchesSectionState extends State<PopularBranchesSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branches.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  _buildSectionHeader(),

                  const SizedBox(height: 20),

                  // Branches Carousel
                  _buildBranchesCarousel(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title with Icon
          Row(
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
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'popular_branches'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.luxuryTextPrimary,
                    ),
                  ),
                  Text(
                    'most_booked'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.luxuryTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // View All Button
          if (widget.onViewAll != null)
            TextButton.icon(
              onPressed: widget.onViewAll,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text('view_all'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBranchesCarousel() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.branches.length,
        itemBuilder: (context, index) {
          final branch = widget.branches[index];
          // Mock data for demonstration - in real app, this would come from backend
          final bookingsCount = 150 + (index * 25);
          final rating = 4.2 + (index * 0.1);

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 20 : 16,
              right: index == widget.branches.length - 1 ? 20 : 0,
            ),
            child: PopularBranchCard(
              branch: branch,
              bookingsCount: bookingsCount,
              rating: rating,
              onTap: () => _onBranchTap(branch),
            ),
          );
        },
      ),
    );
  }

  void _onBranchTap(BranchEntity branch) {
    Navigator.of(
      context,
    ).pushNamed('/branch-details', arguments: {'branchId': branch.id});
  }
}
