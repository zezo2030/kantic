import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/offer_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';

class ModernOfferCard extends StatefulWidget {
  final OfferEntity offer;
  final VoidCallback? onTap;

  const ModernOfferCard({super.key, required this.offer, this.onTap});

  @override
  State<ModernOfferCard> createState() => _ModernOfferCardState();
}

class _ModernOfferCardState extends State<ModernOfferCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: _getOfferGradient(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Background Image or Pattern
                      widget.offer.imageUrl != null &&
                              widget.offer.imageUrl!.isNotEmpty
                          ? _buildBackgroundImage()
                          : _buildBackgroundPattern(),

                      // Gradient Overlay for better text readability
                      _buildGradientOverlay(),

                      // Main Content (simplified)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Title and Venue Badge
                            _buildHeader(),

                            const SizedBox(height: 10),

                            // Discount Chip
                            _buildDiscountChip(),

                            const Spacer(),
                          ],
                        ),
                      ),

                      // Removed countdown and extra badges per simplified design
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundImage() {
    final imageUrl = resolveFileUrl(widget.offer.imageUrl);
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheKey: imageUrl,
        fit: BoxFit.cover,
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(gradient: _getOfferGradient()),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: CustomPaint(painter: _OfferPatternPainter()),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.15),
              Colors.black.withOpacity(0.45),
              Colors.black.withOpacity(0.75),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
        ),
        child: CustomPaint(painter: _OfferPatternPainter()),
      ),
    );
  }

  Widget _buildHeader() {
    final String? branch = (widget.offer.branchName ?? '').trim().isNotEmpty
        ? widget.offer.branchName!.trim()
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildOfferTitle()),
        const SizedBox(width: 8),
        if (branch != null) _venueBadge(branch),
      ],
    );
  }

  Widget _buildOfferTitle() {
    return Text(
      widget.offer.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Description and footer removed in simplified card

  // Countdown removed in simplified card

  // Hot deal badge removed in simplified card

  LinearGradient _getOfferGradient() {
    if (widget.offer.discountValue >= 50) {
      return AppColors.cardGradient;
    } else if (widget.offer.discountValue >= 25) {
      return AppColors.luxuryRoseGradient;
    } else {
      return AppColors.luxuryRedGradient;
    }
  }

  String _getDiscountText() {
    if (widget.offer.discountType == 'percentage') {
      return '${widget.offer.discountValue.toInt()}% ${'off'.tr()}';
    } else {
      return '${widget.offer.discountValue.toInt()} ${'currency'.tr()} ${'off'.tr()}';
    }
  }

  Widget _buildDiscountChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
      ),
      child: Text(
        _getDiscountText(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Venue composition now handled directly in header (branch above, hall below)

  Widget _venueBadge(String? branch) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              branch ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Countdown formatter removed
}

class _OfferPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw circles pattern
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 20.0;
      final center = Offset(
        size.width * 0.8 - (i * 15),
        size.height * 0.2 + (i * 10),
      );

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
