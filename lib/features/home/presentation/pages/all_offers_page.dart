import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/offer_entity.dart';
import '../widgets/modern_offer_card.dart';

class AllOffersPage extends StatelessWidget {
  final List<OfferEntity> offers;

  const AllOffersPage({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('featured_offers'.tr())),
      body: offers.isEmpty
          ? Center(child: Text('no_content_available'.tr()))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ModernOfferCard(offer: offer, onTap: () {}),
                  );
                },
              ),
            ),
    );
  }
}
