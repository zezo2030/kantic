import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/entities/branch_entity.dart';
import 'modern_offer_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/offer_branches_page.dart';

class FeaturedOffersSection extends StatefulWidget {
  final List<OfferEntity> offers;
  final VoidCallback? onViewAll;
  final List<BranchEntity>? featuredBranches;

  const FeaturedOffersSection({
    super.key,
    required this.offers,
    this.onViewAll,
    this.featuredBranches,
  });

  @override
  State<FeaturedOffersSection> createState() => _FeaturedOffersSectionState();
}

class _FeaturedOffersSectionState extends State<FeaturedOffersSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;
  int _currentIndex = 0;

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

    // اجعل الكارد بعرض كامل مع مسافة بين السلايدز
    _pageController = PageController(viewportFraction: 0.92);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) {
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

                  // Offers Carousel
                  _buildOffersCarousel(),

                  const SizedBox(height: 16),

                  // Page Indicators
                  if (widget.offers.length > 1) _buildPageIndicators(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title with Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.glowPrimary,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'featured_offers'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.luxuryTextPrimary,
                    ),
                  ),
                  Text(
                    'best_deals'.tr(),
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

  Widget _buildOffersCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.offers.length,
        itemBuilder: (context, index) {
          final offer = widget.offers[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == widget.offers.length - 1 ? 16 : 8,
            ),
            child: ModernOfferCard(
              offer: offer,
              onTap: () => _onOfferTap(offer),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.offers.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentIndex == index
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _onOfferTap(OfferEntity offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfferBranchesPage(
          offer: offer,
          featuredBranches: widget.featuredBranches,
        ),
      ),
    );
  }
}
