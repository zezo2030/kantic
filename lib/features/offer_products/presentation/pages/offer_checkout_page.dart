import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../cubit/offer_booking_cubit.dart';
import '../../data/models/offer_product_model.dart';
import 'my_offer_bookings_page.dart';

class OfferCheckoutPage extends StatefulWidget {
  final OfferProductModel product;

  const OfferCheckoutPage({super.key, required this.product});

  @override
  State<OfferCheckoutPage> createState() => _OfferCheckoutPageState();
}

class _OfferCheckoutPageState extends State<OfferCheckoutPage> {
  bool _accepted = false;
  Map<String, dynamic>? _quote;
  bool _submitting = false;
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<OfferBookingCubit>()
                ..fetchQuote(offerProductId: widget.product.id),
        ),
        BlocProvider.value(value: payments_di.sl<PaymentCubit>()),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text('offer_checkout'.tr())),
        body: MultiBlocListener(
          listeners: [
            BlocListener<PaymentCubit, PaymentState>(
              listener: (context, state) {
                if (state is PaymentSuccess) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyOfferBookingsPage(),
                    ),
                    (r) => r.isFirst,
                  );
                }
              },
            ),
            BlocListener<OfferBookingCubit, OfferBookingFlowState>(
              listener: (context, state) {
                if (state is OfferBookingFlowQuoteReady) {
                  setState(() => _quote = state.quote);
                }
                if (state is OfferBookingFlowLoading) {
                  setState(() => _submitting = true);
                }
                if (state is OfferBookingFlowCreated) {
                  setState(() => _submitting = false);
                  final r = state.result;
                  final bookingId = r['id']?.toString() ?? '';
                  final total = (r['totalPrice'] is num)
                      ? (r['totalPrice'] as num).toDouble()
                      : widget.product.price;
                  if (bookingId.isNotEmpty) {
                    payments_di.initPayments();
                    context.read<PaymentCubit>().payForOfferBooking(
                          offerBookingId: bookingId,
                          amount: total,
                        );
                  }
                }
                if (state is OfferBookingFlowError) {
                  setState(() => _submitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: Builder(
            builder: (context) {
              if (_quote == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final q = _quote!;
              final total = (q['totalPrice'] is num)
                  ? (q['totalPrice'] as num).toDouble()
                  : widget.product.price;
              final currency = q['currency']?.toString() ?? 'SAR';
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${total.toStringAsFixed(0)} $currency',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        TextField(
                          controller: _phone,
                          decoration: InputDecoration(
                            labelText: 'phone_optional'.tr(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        CheckboxListTile(
                          value: _accepted,
                          onChanged: _submitting
                              ? null
                              : (v) => setState(() => _accepted = v ?? false),
                          title: Text('accept_terms_offer'.tr()),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: (!_accepted || _submitting)
                              ? null
                              : () => context.read<OfferBookingCubit>().submitBooking(
                                    offerProductId: widget.product.id,
                                    contactPhone: _phone.text.trim().isEmpty
                                        ? null
                                        : _phone.text.trim(),
                                    acceptedTerms: true,
                                  ),
                          child: Text('pay_continue'.tr()),
                        ),
                      ],
                    ),
                  ),
                  if (_submitting)
                    const ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
