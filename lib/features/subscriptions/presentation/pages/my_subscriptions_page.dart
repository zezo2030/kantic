import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../cubit/my_subscriptions_cubit.dart';
import 'subscription_details_page.dart';

class MySubscriptionsPage extends StatelessWidget {
  const MySubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MySubscriptionsCubit>()..refresh(),
      child: Scaffold(
        appBar: AppBar(title: Text('my_subscriptions'.tr())),
        body: BlocBuilder<MySubscriptionsCubit, MySubscriptionsState>(
          builder: (context, state) {
            if (state is MySubscriptionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MySubscriptionsError) {
              return Center(child: Text(state.message));
            }
            if (state is MySubscriptionsLoaded) {
              if (state.items.isEmpty) {
                return Center(child: Text('subscriptions_empty'.tr()));
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
                          context.read<MySubscriptionsCubit>().loadMore(),
                      child: Text('load_more'.tr()),
                    );
                  }
                  final p = state.items[i];
                  return ListTile(
                    title: Text(p.planTitle),
                    subtitle: Text(
                      '${p.status} · ${p.paymentStatus}',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SubscriptionDetailsPage(purchaseId: p.id),
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
