import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/models/offer_product_model.dart';
import 'offer_checkout_page.dart';

class OfferProductDetailsPage extends StatelessWidget {
  final OfferProductModel product;

  const OfferProductDetailsPage({super.key, required this.product});

  bool get _isTicket => product.offerCategory == 'ticket_based';

  @override
  Widget build(BuildContext context) {
    final gradient = _isTicket
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B2FF7), Color(0xFF9D46FF), Color(0xFFBF6FFF)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00897B), Color(0xFF00ACC1), Color(0xFF26C6DA)],
          );

    final resolvedUrl = product.imageUrl != null && product.imageUrl!.isNotEmpty
        ? resolveFileUrl(product.imageUrl!)
        : null;

    final accentColor = _isTicket ? const Color(0xFF7B2FF7) : const Color(0xFF00897B);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              resolvedUrl: resolvedUrl,
              maxHeight: 280,
              minHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
              title: product.title,
              gradient: gradient,
              accentColor: accentColor,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildBody(context, accentColor),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, accentColor),
    );
  }

  Widget _buildBody(BuildContext context, Color accentColor) {
    final categoryLabel = _isTicket ? 'ticket'.tr() : 'hours'.tr();
    final categoryIcon = _isTicket ? Iconsax.ticket : Iconsax.clock;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      transform: Matrix4.translationValues(0, -32, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Gift Icon Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (product.isGiftable)
                  Container(
                    margin: const EdgeInsets.only(left: 12, right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.gift, color: Colors.amber, size: 24),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Price & Category Row
            Row(
              children: [
                Text(
                  '${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)} ${product.currency.tr()}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(categoryIcon, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            if (product.description != null && product.description!.isNotEmpty) ...[
              _buildSectionTitle('about_offer'.tr()),
              const SizedBox(height: 12),
              Text(
                product.description!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (product.termsAndConditions != null &&
                product.termsAndConditions!.isNotEmpty) ...[
              _buildSectionTitle('terms_and_conditions'.tr()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Text(
                  product.termsAndConditions!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
            
            // Extra spacing for bottom bar
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Color accentColor) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfferCheckoutPage(product: product),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: accentColor.withOpacity(0.5),
          ),
          child: Text(
            'buy_offer'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String? resolvedUrl;
  final double maxHeight;
  final double minHeight;
  final String title;
  final LinearGradient gradient;
  final Color accentColor;

  _HeaderDelegate({
    required this.resolvedUrl,
    required this.maxHeight,
    required this.minHeight,
    required this.title,
    required this.gradient,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxHeight;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (resolvedUrl != null)
          CachedNetworkImage(
            imageUrl: resolvedUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: accentColor),
            errorWidget: (_, __, ___) => Container(color: accentColor),
          )
        else
          Container(decoration: BoxDecoration(gradient: gradient)),
        
        // Dark Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(resolvedUrl != null ? 0.6 : 0.2),
              ],
            ),
          ),
        ),

        // Title that fades in when scrolling up
        Positioned(
          bottom: 16,
          left: 48,
          right: 48,
          child: Opacity(
            opacity: progress > 0.8 ? ((progress - 0.8) * 5).clamp(0.0, 1.0) : 0.0,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return resolvedUrl != oldDelegate.resolvedUrl ||
        maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        title != oldDelegate.title ||
        gradient != oldDelegate.gradient ||
        accentColor != oldDelegate.accentColor;
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;
}
