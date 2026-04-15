import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../domain/usecases/get_offer_booking_details_usecase.dart';
import '../../domain/usecases/get_offer_booking_tickets_usecase.dart';
import '../../data/models/offer_booking_model.dart';
import '../../data/models/offer_ticket_model.dart';
import '../../../../core/theme/app_colors.dart';
import 'offer_moyasar_payment_page.dart';
import 'offer_ticket_page.dart';

class OfferBookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const OfferBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<OfferBookingDetailsPage> createState() =>
      _OfferBookingDetailsPageState();
}

class _OfferBookingDetailsPageState extends State<OfferBookingDetailsPage> {
  OfferBookingModel? _booking;
  List<OfferTicketModel> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await sl<GetOfferBookingDetailsUseCase>()(widget.bookingId);
      final t = await sl<GetOfferBookingTicketsUseCase>()(widget.bookingId);
      setState(() {
        _booking = b;
        _tickets = t;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: payments_di.sl<PaymentCubit>(),
      child: BlocListener<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            _load();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('payment_success'.tr()),
                  backgroundColor: AppColors.successColor,
                ),
              );
            }
          } else if (state is PaymentIntentCreated) {
            final redirect = state.intent.redirectUrl;
            if (redirect == null || redirect.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted || _booking == null) return;
                final paid = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => OfferMoyasarPaymentPage(
                      offerBookingId: widget.bookingId,
                      paymentId: state.intent.paymentId,
                      amount: state.intent.amount ?? _booking!.totalPrice,
                    ),
                  ),
                );
                if (!context.mounted) return;
                if (paid == true) {
                  await _load();
                }
              });
            }
          } else if (state is PaymentFailure) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'offer_booking_details'.tr(),
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          body: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryRed),
                )
              : _error != null
                  ? _buildError()
                  : _booking == null
                      ? const SizedBox.shrink()
                      : _buildContent(),
          bottomNavigationBar: _booking != null ? _buildBottomBar() : null,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2,
                size: 48, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'retry'.tr(),
                style: const TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final b = _booking!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingHeader(b),
            const SizedBox(height: 24),
            _buildPaymentStatusCard(b),
            const SizedBox(height: 24),
            _buildPriceBreakdownCard(b),
            if (_tickets.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildTicketsSection(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHeader(OfferBookingModel b) {
    final isActive = b.status.toLowerCase() == 'active';
    final statusColor = _getStatusColor(b.status);

    return GestureDetector(
      onTap: _tickets.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OfferTicketPage(ticket: _tickets.first),
                ),
              );
            },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Container(
                width: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7B2FF7),
                      Color(0xFF312E81),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Iconsax.ticket_star : Iconsax.ticket_expired,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_tickets.length}',
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'tickets'.tr(),
                      style: TextStyle(
                        fontFamily: 'MontserratArabic',
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 20,
                child: Stack(
                  children: [
                    Container(color: Colors.white),
                    Positioned(
                      top: -10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(10, (index) {
                          return Container(
                            width: 2,
                            height: 6,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'MontserratArabic',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              b.status.tr(),
                              style: TextStyle(
                                fontFamily: 'MontserratArabic',
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${b.totalPrice.toStringAsFixed(b.totalPrice % 1 == 0 ? 0 : 2)} ${b.offerSnapshot['currency'] ?? 'SAR'}',
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${b.id.substring(0, b.id.length > 8 ? 8 : b.id.length)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: AppColors.textHint,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Clipboard.setData(ClipboardData(text: b.id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('id_copied'.tr())),
                                  );
                                },
                                child: const Icon(
                                  Iconsax.copy,
                                  size: 16,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ],
                          ),
                          if (_tickets.isNotEmpty &&
                              _tickets.first.qrData != null)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showQrDialog(context, _tickets.first.qrData!);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B2FF7),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7B2FF7)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Iconsax.scan_barcode,
                                        size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'QR',
                                      style: TextStyle(
                                        fontFamily: 'MontserratArabic',
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard(OfferBookingModel b) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Iconsax.card, size: 20, color: AppColors.primaryRed),
            const SizedBox(width: 16),
            Text(
              'payment_status'.tr(),
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              b.paymentStatus.tr(),
              style: TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 14,
                color: _isPaid(b)
                    ? AppColors.successColor
                    : AppColors.warningColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownCard(OfferBookingModel b) {
    final currency = b.offerSnapshot['currency']?.toString() ?? 'SAR';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.receipt_item,
                    color: AppColors.primaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'billing_details'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPriceRow('subscription_base_price'.tr(),
              '${b.subtotal.toStringAsFixed(b.subtotal % 1 == 0 ? 0 : 2)} $currency'),
          if (b.addonsTotal > 0)
            _buildPriceRow('add_ons'.tr(),
                '${b.addonsTotal.toStringAsFixed(b.addonsTotal % 1 == 0 ? 0 : 2)} $currency'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildPriceRow(
            'total'.tr(),
            '${b.totalPrice.toStringAsFixed(b.totalPrice % 1 == 0 ? 0 : 2)} $currency',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: bold ? 16 : 14,
              color: AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FF7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.ticket,
                  color: Color(0xFF7B2FF7), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'tickets'.tr(),
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_tickets.length, (i) {
          final t = _tickets[i];
          final ticketStatusColor = _getTicketStatusColor(t.status);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OfferTicketPage(ticket: t),
              ),
            ),
            child: Container(
              margin: EdgeInsets.only(bottom: i < _tickets.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ticketStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Iconsax.ticket,
                        color: ticketStatusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'ticket'.tr()} #${i + 1}',
                          style: const TextStyle(
                            fontFamily: 'MontserratArabic',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.ticketKind.tr(),
                          style: const TextStyle(
                            fontFamily: 'MontserratArabic',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticketStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      t.status.tr(),
                      style: TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ticketStatusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Iconsax.arrow_left_2,
                      size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showQrDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.scan_barcode,
                  color: Color(0xFF7B2FF7), size: 32),
              const SizedBox(height: 12),
              Text(
                'my_qr_code'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'use_at_counter'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2FF7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'close'.tr(),
                    style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPaid(OfferBookingModel b) {
    final ps = b.paymentStatus.toLowerCase().trim();
    const paidStates = {'paid', 'completed', 'success', 'succeeded', 'complete'};
    return paidStates.contains(ps);
  }

  bool _bookingNeedsPayment(OfferBookingModel b) {
    final st = b.status.toLowerCase();
    if (st.contains('cancel') || st.contains('refund')) return false;
    return !_isPaid(b);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.successColor;
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return AppColors.errorColor;
      default:
        return AppColors.warningColor;
    }
  }

  Color _getTicketStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
      case 'active':
        return AppColors.successColor;
      case 'used':
      case 'scanned':
        return const Color(0xFF3B82F6);
      case 'expired':
        return AppColors.errorColor;
      default:
        return AppColors.warningColor;
    }
  }

  Widget _buildBottomBar() {
    final b = _booking!;
    final needsPayment = _bookingNeedsPayment(b);
    final bottomPad = MediaQuery.of(context).padding.bottom + 16;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: needsPayment
          ? BlocBuilder<PaymentCubit, PaymentState>(
              builder: (context, payState) {
                final busy = payState is PaymentLoading;
                return FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          payments_di.initPayments();
                          context.read<PaymentCubit>().payForOfferBooking(
                                offerBookingId: widget.bookingId,
                                amount: b.totalPrice,
                              );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Iconsax.card_send, size: 20),
                  label: Text(
                    'pay_now'.tr(),
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
