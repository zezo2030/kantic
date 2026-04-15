import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/offer_product_model.dart';
import 'offer_checkout_page.dart';

class OfferProductDetailsPage extends StatelessWidget {
  final OfferProductModel product;

  const OfferProductDetailsPage({super.key, required this.product});

  bool get _isTicket => product.offerCategory == 'ticket_based';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        title: Text('offer_product_details'.tr()),
        centerTitle: true,
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'MontserratArabic',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBody(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Gift Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              if (product.isGiftable)
                Container(
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Iconsax.gift, color: Colors.amber, size: 24),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)} ${product.currency.tr()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Key Features Section
          Text(
            'offer_summary'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildModernFeatureItem(
                context,
                icon: _isTicket ? Iconsax.ticket : Iconsax.clock,
                title: 'offer_type'.tr(),
                value: _isTicket ? 'ticket'.tr() : 'hours'.tr(),
              ),
              if (_isTicket && product.ticketConfig != null)
                _buildModernFeatureItem(
                  context,
                  icon: Iconsax.ticket,
                  title: 'ticket_count'.tr(),
                  value: '${product.ticketConfig!['ticketCount'] ?? 0} ${'tickets'.tr()}',
                ),
              if (!_isTicket && product.hoursConfig != null)
                _buildModernFeatureItem(
                  context,
                  icon: Iconsax.clock,
                  title: 'subscriptions_total_hours'.tr(),
                  value: '${product.hoursConfig!['totalHours'] ?? 0} ${'hours'.tr()}',
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
                color: AppColors.textSecondary,
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
                color: AppColors.luxurySurfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                product.termsAndConditions!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 60), // Extra safety spacing
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModernFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48 - 12) / 2, // 2 items per row max
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.luxurySurfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfferCheckoutPage(product: product),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          icon: const Icon(Iconsax.card_send, size: 22),
          label: Text(
            'buy_offer'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

