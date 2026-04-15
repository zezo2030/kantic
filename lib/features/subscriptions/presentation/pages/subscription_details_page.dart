import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/subscription_ticket_widget.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../domain/usecases/get_subscription_details_usecase.dart';
import '../../data/models/subscription_purchase_model.dart';
import '../../../../core/theme/app_colors.dart';
import 'subscription_moyasar_payment_page.dart';
import 'subscription_usage_logs_page.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  final String purchaseId;

  const SubscriptionDetailsPage({super.key, required this.purchaseId});

  @override
  State<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  SubscriptionPurchaseModel? _purchase;
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
      final p = await sl<GetSubscriptionDetailsUseCase>()(widget.purchaseId);
      setState(() {
        _purchase = p;
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
                if (!context.mounted || _purchase == null) return;
                final paid = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => SubscriptionMoyasarPaymentPage(
                      subscriptionPurchaseId: widget.purchaseId,
                      paymentId: state.intent.paymentId,
                      amount:
                          state.intent.amount ??
                          _payAmountFromSnapshot(_purchase!),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
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
              'subscription_details'.tr(),
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
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                )
              : _error != null
              ? _buildError()
              : _purchase == null
              ? const SizedBox.shrink()
              : _buildContent(),
          bottomNavigationBar: _purchase != null ? _buildBottomBar() : null,
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
            const Icon(
              Iconsax.warning_2,
              size: 48,
              color: AppColors.errorColor,
            ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'retry'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _purchase!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubscriptionTicketWidget(
            purchase: p,
            onViewQr: () {
              if (p.qrData != null && p.qrData!.isNotEmpty) {
                _showQrDialog(context, p.qrData!);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('no_qr_available'.tr())));
              }
            },
            onCopyId: () {
              Clipboard.setData(ClipboardData(text: p.id));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('id_copied'.tr())));
            },
          ),
          const SizedBox(height: 32),
          if (p.remainingHours != null || p.totalHours != null) ...[
            _buildHoursCard(p),
            const SizedBox(height: 24),
          ],
          _buildPaymentStatusCard(p),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHoursCard(SubscriptionPurchaseModel p) {
    final double progress = (p.totalHours == null || p.totalHours == 0)
        ? 1.0
        : (p.remainingHours ?? p.totalHours!) / p.totalHours!;

    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.timer_1,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'subscriptions_remaining_hours'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      progress > 0.3
                          ? AppColors.primaryRed
                          : progress > 0
                          ? AppColors.warningColor
                          : AppColors.errorColor,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.remainingHours?.toStringAsFixed(
                            p.remainingHours! % 1 == 0 ? 0 : 1,
                          ) ??
                          '—',
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 32,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'hours'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'subscriptions_total_hours'.tr(),
                  p.totalHours?.toStringAsFixed(
                        p.totalHours! % 1 == 0 ? 0 : 1,
                      ) ??
                      '—',
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.withOpacity(0.3),
                ),
                _buildStatItem(
                  'subscriptions_daily_limit'.tr(),
                  p.dailyHoursLimit != null
                      ? '${p.dailyHoursLimit!.toStringAsFixed(p.dailyHoursLimit! % 1 == 0 ? 0 : 1)} ${'hours'.tr()}'
                      : 'subscription_unlimited'.tr(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard(SubscriptionPurchaseModel p) {
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
      child: Column(
        children: [
          _buildInfoRow(
            icon: Iconsax.card,
            label: 'payment_status'.tr(),
            value: p.paymentStatus.tr(),
            valueColor:
                p.paymentStatus.toLowerCase() == 'paid' ||
                    p.paymentStatus.toLowerCase() == 'completed'
                ? AppColors.successColor
                : AppColors.warningColor,
            isFirst: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isFirst ? 20 : 16,
        bottom: isLast ? 20 : 16,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryRed),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Iconsax.scan_barcode,
                color: AppColors.primaryRed,
                size: 32,
              ),
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
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'close'.tr(),
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _purchaseNeedsPayment(SubscriptionPurchaseModel p) {
    final st = p.status.toLowerCase();
    if (st.contains('cancel') || st.contains('refund')) return false;
    final ps = p.paymentStatus.toLowerCase().trim();
    const paidStates = {
      'paid',
      'completed',
      'success',
      'succeeded',
      'complete',
    };
    return !paidStates.contains(ps);
  }

  double _payAmountFromSnapshot(SubscriptionPurchaseModel p) {
    final snap = p.planSnapshot;
    const keys = ['totalPrice', 'amount', 'total', 'grandTotal', 'price'];
    for (final k in keys) {
      final raw = snap[k];
      if (raw is num) return raw.toDouble();
      final parsed = double.tryParse(raw?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  Widget _buildBottomBar() {
    final p = _purchase!;
    final needsPayment = _purchaseNeedsPayment(p);
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
                          context
                              .read<PaymentCubit>()
                              .payForSubscriptionPurchase(
                                subscriptionPurchaseId: widget.purchaseId,
                                amount: _payAmountFromSnapshot(p),
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
          : ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubscriptionUsageLogsPage(
                      purchaseId: widget.purchaseId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.document_text, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'subscription_usage_logs'.tr(),
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
