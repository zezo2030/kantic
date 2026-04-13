import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/offer_product_model.dart';
import 'offer_checkout_page.dart';

class OfferProductDetailsPage extends StatelessWidget {
  final OfferProductModel product;

  const OfferProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${product.price} ${product.currency}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(product.offerCategory),
          if (product.description != null) Text(product.description!),
          if (product.termsAndConditions != null) ...[
            const SizedBox(height: 16),
            Text('terms_and_conditions'.tr()),
            Text(product.termsAndConditions!),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OfferCheckoutPage(product: product),
              ),
            ),
            child: Text('buy_offer'.tr()),
          ),
        ],
      ),
    );
  }
}
