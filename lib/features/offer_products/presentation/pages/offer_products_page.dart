import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../cubit/offer_products_cubit.dart';
import 'offer_product_details_page.dart';

class OfferProductsPage extends StatelessWidget {
  final String branchId;

  const OfferProductsPage({super.key, required this.branchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OfferProductsCubit>()..load(branchId),
      child: Scaffold(
        appBar: AppBar(title: Text('offer_products_title'.tr())),
        body: BlocBuilder<OfferProductsCubit, OfferProductsState>(
          builder: (context, state) {
            if (state is OfferProductsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OfferProductsError) {
              return Center(child: Text(state.message));
            }
            if (state is OfferProductsLoaded) {
              final all = [...state.ticketOffers, ...state.hoursOffers];
              if (all.isEmpty) {
                return Center(child: Text('offer_products_empty'.tr()));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: all.length,
                itemBuilder: (context, i) {
                  final o = all[i];
                  return Card(
                    child: ListTile(
                      title: Text(o.title),
                      subtitle: Text(
                        '${o.offerCategory} · ${o.price} ${o.currency}',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfferProductDetailsPage(product: o),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
