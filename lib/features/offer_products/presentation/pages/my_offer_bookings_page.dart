import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../cubit/my_offer_bookings_cubit.dart';
import 'offer_booking_details_page.dart';

class MyOfferBookingsPage extends StatelessWidget {
  const MyOfferBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyOfferBookingsCubit>()..refresh(),
      child: Scaffold(
        appBar: AppBar(title: Text('my_offer_bookings'.tr())),
        body: BlocBuilder<MyOfferBookingsCubit, MyOfferBookingsState>(
          builder: (context, state) {
            if (state is MyOfferBookingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyOfferBookingsError) {
              return Center(child: Text(state.message));
            }
            if (state is MyOfferBookingsLoaded) {
              if (state.items.isEmpty) {
                return Center(child: Text('offer_products_empty'.tr()));
              }
              return ListView.builder(
                itemCount: state.items.length + 1,
                itemBuilder: (context, i) {
                  if (i == state.items.length) {
                    if (state.page >= state.totalPages) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () =>
                          context.read<MyOfferBookingsCubit>().loadMore(),
                      child: Text('load_more'.tr()),
                    );
                  }
                  final b = state.items[i];
                  return ListTile(
                    title: Text(b.title),
                    subtitle: Text(
                      '${b.status} · ${b.totalPrice} ${b.offerSnapshot['currency'] ?? ''}',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OfferBookingDetailsPage(bookingId: b.id),
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
