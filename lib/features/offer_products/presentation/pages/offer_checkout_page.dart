import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../data/models/offer_product_model.dart';
import '../cubit/offer_booking_cubit.dart';
import 'my_offer_bookings_page.dart';
import 'offer_booking_details_page.dart';
import 'offer_moyasar_payment_page.dart';

class OfferCheckoutPage extends StatefulWidget {
  final OfferProductModel product;

  const OfferCheckoutPage({super.key, required this.product});

  @override
  State<OfferCheckoutPage> createState() => _OfferCheckoutPageState();
}

class _OfferCheckoutPageState extends State<OfferCheckoutPage> {
  bool _accepted = false;
  bool _isQuoteLoading = true;
  bool _isSubmitting = false;
  bool _hasConflict = false;
  Map<String, dynamic>? _quote;
  String? _quoteErrorMessage;
  String? _latestCreatedBookingId;
  String _selectedPaymentMethod = 'credit_card';
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _isTicket => widget.product.offerCategory == 'ticket_based';

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
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.luxurySurfaceVariant,
          appBar: AppBar(title: Text('offer_checkout'.tr())),
          body: MultiBlocListener(
            listeners: [
              BlocListener<PaymentCubit, PaymentState>(
                listener: (context, state) async {
                  if (state is PaymentSuccess) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyOfferBookingsPage(),
                      ),
                      (route) => route.isFirst,
                    );
                  } else if (state is PaymentIntentCreated) {
                    if (_selectedPaymentMethod == 'wallet') {
                      return;
                    }

                    final redirect = state.intent.redirectUrl;
                    if (redirect != null && redirect.isNotEmpty) {
                      return;
                    }

                    final bookingId = _latestCreatedBookingId;
                    if (bookingId == null || bookingId.isEmpty) {
                      return;
                    }

                    final paid = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => OfferMoyasarPaymentPage(
                          offerBookingId: bookingId,
                          paymentId: state.intent.paymentId,
                          amount: state.intent.amount ?? _quoteTotal,
                        ),
                      ),
                    );

                    if (!context.mounted) return;
                    if (paid == true) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyOfferBookingsPage(),
                        ),
                        (route) => route.isFirst,
                      );
                    }
                  } else if (state is PaymentFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
              ),
              BlocListener<OfferBookingCubit, OfferBookingFlowState>(
                listener: (context, state) {
                  if (state is OfferBookingFlowQuoteReady) {
                    setState(() {
                      _quote = state.quote;
                      _isQuoteLoading = false;
                      _isSubmitting = false;
                      _hasConflict = false;
                      _quoteErrorMessage = null;
                    });
                  }

                  if (state is OfferBookingFlowLoading && _quote != null) {
                    setState(() => _isSubmitting = true);
                  }

                  if (state is OfferBookingFlowConflict) {
                    setState(() {
                      _isQuoteLoading = false;
                      _isSubmitting = false;
                      _hasConflict = true;
                      _quoteErrorMessage = state.message;
                    });
                  }

                  if (state is OfferBookingFlowCreated) {
                    setState(() => _isSubmitting = false);
                    final result = state.result;
                    final paymentRequired =
                        result['paymentRequired'] == true ||
                            (result['paymentStatus']?.toString().toLowerCase() !=
                                'paid');
                    final bookingId = result['id']?.toString() ?? '';
                    _latestCreatedBookingId = bookingId;

                    if (!paymentRequired && bookingId.isNotEmpty) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OfferBookingDetailsPage(bookingId: bookingId),
                        ),
                      );
                      return;
                    }

                    if (bookingId.isNotEmpty) {
                      _showPaymentMethodSheet(context, bookingId);
                    }
                  }

                  if (state is OfferBookingFlowError) {
                    setState(() {
                      _isQuoteLoading = false;
                      _isSubmitting = false;
                      _quoteErrorMessage = state.message;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
              ),
            ],
            child: _isQuoteLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasConflict
                    ? _buildConflictState(context)
                    : _quote == null
                        ? _buildQuoteErrorState(context)
                        : Stack(
                            children: [
                              SafeArea(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 140,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildHeroCard(context),
                                            const SizedBox(height: 16),
                                            _buildDetailsCard(context),
                                            const SizedBox(height: 16),
                                            _buildBillingCard(context),
                                            const SizedBox(height: 16),
                                            _buildPhoneCard(context),
                                            const SizedBox(height: 16),
                                            _buildTermsCard(context),
                                            const SizedBox(height: 16),
                                            _buildAcceptanceCard(context),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildBottomActionBar(context),
                              if (_isSubmitting)
                                const ColoredBox(
                                  color: Color(0x33000000),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                            ],
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepRed.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderBadge(
                  icon: _isTicket ? Iconsax.ticket : Iconsax.clock,
                  label: _isTicket ? 'ticket'.tr() : 'hours'.tr(),
                  color: Colors.white,
                ),
                if (widget.product.isGiftable)
                  _buildHeaderBadge(
                    icon: Iconsax.gift,
                    label: 'subscription_giftable'.tr(),
                    color: AppColors.luxuryGold,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.product.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'offer_checkout_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 28),

            // Price Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'offer_due_today'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_quoteTotal, _currency),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryRed, AppColors.primaryOrange],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Iconsax.card_tick, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics Layout
            Row(
              children: [
                Expanded(
                  child: _buildHeroMetric(
                    context,
                    icon: _isTicket ? Iconsax.ticket : Iconsax.clock,
                    label: 'type'.tr(),
                    value: _isTicket ? 'ticket'.tr() : 'hours'.tr(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeroMetric(
                    context,
                    icon: Iconsax.money,
                    label: 'price'.tr(),
                    value: _formatCurrency(widget.product.price, widget.product.currency),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailsCard(BuildContext context) {
    final items = <Widget>[];

    if (widget.product.offerCategory == 'ticket_based' &&
        widget.product.ticketConfig != null) {
      final tc = widget.product.ticketConfig!;
      if (tc['ticketCount'] != null) {
        items.add(_buildInfoTile(
          context,
          icon: Iconsax.ticket,
          title: 'ticket_count'.tr(),
          value: '${tc['ticketCount']}',
        ));
      }
    }

    if (widget.product.offerCategory == 'hour_based' &&
        widget.product.hoursConfig != null) {
      final hc = widget.product.hoursConfig!;
      if (hc['totalHours'] != null) {
        items.add(_buildInfoTile(
          context,
          icon: Iconsax.clock,
          title: 'subscriptions_total_hours'.tr(),
          value: '${hc['totalHours']} ${'hours'.tr()}',
        ));
      }
    }

    if (widget.product.includedAddOns.isNotEmpty) {
      items.add(_buildInfoTile(
        context,
        icon: Iconsax.add_circle,
        title: 'add_ons'.tr(),
        value: '${widget.product.includedAddOns.length} ${'items'.tr()}',
        isLast: true,
      ));
    }

    if (items.isEmpty) {
      items.add(_buildInfoTile(
        context,
        icon: Iconsax.info_circle,
        title: 'offer_type'.tr(),
        value: _isTicket ? 'ticket'.tr() : 'hours'.tr(),
        isLast: true,
      ));
    }

    return _buildSurfaceCard(
      context,
      title: 'offer_summary'.tr(),
      subtitle: 'offer_summary_hint'.tr(),
      child: Column(
        children: [
          ...items,
          if ((widget.product.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                widget.product.description!.trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingCard(BuildContext context) {
    final base = _readAmount(
      _quote,
      ['basePrice', 'subtotal', 'subTotal', 'price'],
      fallback: widget.product.price,
    );
    final addons = _readAmount(_quote, ['addonsTotal', 'addOnsTotal']);
    final discount = _readAmount(_quote, ['discount', 'discountAmount']);
    final tax = _readAmount(_quote, ['tax', 'vat', 'taxAmount', 'vatAmount']);
    final fees = _readAmount(
      _quote,
      ['fees', 'serviceFee', 'serviceFees', 'processingFee'],
    );

    return _buildSurfaceCard(
      context,
      title: 'billing_details'.tr(),
      subtitle: 'offer_billing_hint'.tr(),
      child: Column(
        children: [
          _buildAmountRow(
            context,
            label: 'subscription_base_price'.tr(),
            value: _formatCurrency(base, _currency),
          ),
          if (addons > 0)
            _buildAmountRow(
              context,
              label: 'add_ons'.tr(),
              value: _formatCurrency(addons, _currency),
            ),
          if (discount > 0)
            _buildAmountRow(
              context,
              label: 'subscription_discount'.tr(),
              value: '- ${_formatCurrency(discount, _currency)}',
              valueColor: AppColors.successColor,
            ),
          if (tax > 0)
            _buildAmountRow(
              context,
              label: 'subscription_tax'.tr(),
              value: _formatCurrency(tax, _currency),
            ),
          if (fees > 0)
            _buildAmountRow(
              context,
              label: 'subscription_fees'.tr(),
              value: _formatCurrency(fees, _currency),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            context,
            label: 'offer_due_today'.tr(),
            value: _formatCurrency(_quoteTotal, _currency),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard(BuildContext context) {
    return _buildSurfaceCard(
      context,
      title: 'contact_info'.tr(),
      subtitle: 'phone_optional'.tr(),
      child: TextField(
        controller: _phone,
        decoration: InputDecoration(
          hintText: 'phone_optional'.tr(),
          prefixIcon: const Icon(Iconsax.call, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primaryRed),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: TextInputType.phone,
      ),
    );
  }

  Widget _buildTermsCard(BuildContext context) {
    final terms = widget.product.termsAndConditions?.trim();

    return _buildSurfaceCard(
      context,
      title: 'terms_and_conditions'.tr(),
      subtitle: 'offer_terms_hint'.tr(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          terms == null || terms.isEmpty
              ? 'subscription_terms_unavailable'.tr()
              : terms,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
        ),
      ),
    );
  }

  Widget _buildAcceptanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _accepted
              ? AppColors.primaryRed.withOpacity(0.22)
              : AppColors.borderLight,
        ),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _accepted,
        onChanged: _isSubmitting
            ? null
            : (value) => setState(() => _accepted = value ?? false),
        title: Text(
          'accept_terms_offer'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'offer_acceptance_note'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'offer_due_today'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_quoteTotal, _currency),
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: (!_accepted || _isSubmitting)
                      ? null
                      : () => context
                          .read<OfferBookingCubit>()
                          .submitBooking(
                            offerProductId: widget.product.id,
                            contactPhone: _phone.text.trim().isEmpty
                                ? null
                                : _phone.text.trim(),
                            acceptedTerms: true,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Iconsax.card_send, size: 18),
                  label: Text('pay_continue'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Iconsax.warning_2,
              color: AppColors.warningColor,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              _quoteErrorMessage?.trim().isNotEmpty == true
                  ? _quoteErrorMessage!
                  : 'payment_info_not_found'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _retryQuote(context),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColorLight,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.lightRed,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Iconsax.shield_search,
                  color: AppColors.primaryRed,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'offer_conflict_title'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'offer_conflict_desc'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
              ),
              if (_quoteErrorMessage?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Text(
                  _quoteErrorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyOfferBookingsPage(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Iconsax.receipt_item),
                label: Text('my_offer_bookings'.tr()),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('back'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurfaceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String label,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.luxurySurfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.lightRed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    BuildContext context, {
    required String label,
    required String value,
    bool emphasize = false,
    Color? valueColor,
  }) {
    final textStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            value,
            style: textStyle?.copyWith(color: valueColor ?? textStyle.color),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final value =
        amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    return '$value $currency';
  }

  double _readAmount(
    Map<String, dynamic>? source,
    List<String> keys, {
    double fallback = 0,
  }) {
    if (source == null) return fallback;
    for (final key in keys) {
      final raw = source[key];
      if (raw is num) return raw.toDouble();
      final parsed = double.tryParse(raw?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String get _currency =>
      _quote?['currency']?.toString() ?? widget.product.currency.tr();

  double get _quoteTotal => _readAmount(
        _quote,
        ['totalPrice', 'amount', 'total', 'grandTotal'],
        fallback: widget.product.price,
      );

  void _showPaymentMethodSheet(BuildContext pageContext, String bookingId) {
    final total = _quoteTotal;
    final authState = pageContext.read<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;
    final walletBalance = user?.wallet?.balance ?? 0.0;
    final hasEnoughBalance = walletBalance >= total;

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'select_payment_method'.tr(),
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            BlocProvider(
              create: (_) {
                final cubit = GetIt.instance<WalletCubit>();
                if (cubit.state is WalletInitial) {
                  cubit.loadWallet();
                }
                return cubit;
              },
              child: BlocBuilder<WalletCubit, WalletState>(
                builder: (_, walletState) {
                  double currentBalance = walletBalance;
                  bool currentHasEnough = hasEnoughBalance;

                  if (walletState is WalletLoaded) {
                    currentBalance = walletState.wallet.balance;
                    currentHasEnough = currentBalance >= total;
                  }

                  return Column(
                    children: [
                      _buildPaymentMethodTile(
                        icon: Iconsax.card,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'credit_card'.tr(),
                        subtitle: 'visa_mastercard'.tr(),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _startPayment(
                              pageContext, bookingId, 'credit_card');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodTile(
                        icon: Iconsax.wallet_3,
                        iconColor: AppColors.luxuryGold,
                        title: 'pay_with_wallet'.tr(),
                        subtitle: currentHasEnough
                            ? '${'wallet_balance'.tr()}: ${currentBalance.toStringAsFixed(2)} ${'currency'.tr()}'
                            : 'insufficient_balance'.tr(),
                        enabled: currentHasEnough,
                        onTap: currentHasEnough
                            ? () {
                                Navigator.pop(sheetContext);
                                _startPayment(
                                    pageContext, bookingId, 'wallet');
                              }
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startPayment(
      BuildContext blocContext, String bookingId, String method) {
    _selectedPaymentMethod = method;
    payments_di.initPayments();
    blocContext.read<PaymentCubit>().payForOfferBooking(
          offerBookingId: bookingId,
          amount: _quoteTotal,
          method: method,
        );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap?.call();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(enabled ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: enabled ? iconColor : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? const Color(0xFF64748B)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_1,
              size: 20,
              color: enabled
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  void _retryQuote(BuildContext blocContext) {
    setState(() {
      _isQuoteLoading = true;
      _isSubmitting = false;
      _hasConflict = false;
      _quoteErrorMessage = null;
    });
    blocContext
        .read<OfferBookingCubit>()
        .fetchQuote(offerProductId: widget.product.id);
  }
}
