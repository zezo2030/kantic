import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/presentation/widgets/modern_ticket_widget.dart';
import '../../di/trips_injection.dart' as trips_di;
import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/entities/trip_request_status.dart';
import '../cubit/trip_request_details_cubit.dart';
import '../cubit/trip_request_details_state.dart';
import 'trip_request_moyasar_payment_page.dart';

double _tripTicketsSubtotalForPay(SchoolTripRequestEntity request) {
  final perStudent = request.pricePerStudent ??
      ((request.quotedPrice ?? 0) /
          (request.studentsCount == 0 ? 1 : request.studentsCount));
  return perStudent * request.studentsCount;
}

double _tripAddOnsSubtotalForPay(SchoolTripRequestEntity request) =>
    request.addOns.fold<double>(0, (s, a) => s + a.price * a.quantity);

double _tripGrandTotalForPay(SchoolTripRequestEntity request) =>
    request.totalPrice ??
    request.quotedPrice ??
    (_tripTicketsSubtotalForPay(request) + _tripAddOnsSubtotalForPay(request));

double _tripDepositForPay(SchoolTripRequestEntity request) =>
    request.depositAmount ?? (_tripGrandTotalForPay(request) * 0.2);

/// المتبقي بعد العربون (يُعرض في التفاصيل؛ يُسدد في الفرع بعد دفع العربون من التطبيق).
double tripRemainingBalanceSar(SchoolTripRequestEntity request) {
  final grand = _tripGrandTotalForPay(request);
  final deposit = _tripDepositForPay(request);
  if (request.status == TripRequestStatus.depositPaid) {
    if (request.remainingAmount != null && request.remainingAmount! >= 0) {
      return request.remainingAmount!;
    }
    final paid = request.amountPaid ?? deposit;
    final left = grand - paid;
    return left > 0 ? left : 0;
  }
  if (request.paymentOption == 'deposit' || request.depositAmount != null) {
    final left = grand - deposit;
    return left > 0 ? left : 0;
  }
  return 0;
}

/// المبلغ القابل للدفع داخل التطبيق (بعد دفع العربون يُكمّل المتبقي في الفرع فقط).
double tripPayableAmountSar(SchoolTripRequestEntity request) {
  if (request.status == TripRequestStatus.depositPaid) {
    return 0;
  }
  final grand = _tripGrandTotalForPay(request);
  if (request.paymentOption == 'deposit') {
    return _tripDepositForPay(request);
  }
  return grand;
}

String tripPayableAmountLabel(SchoolTripRequestEntity request) {
  if ((request.status == TripRequestStatus.approved ||
          request.status == TripRequestStatus.invoiced) &&
      request.paymentOption == 'deposit') {
    return 'trip_deposit'.tr();
  }
  return 'total_amount'.tr();
}

class TripRequestDetailsPage extends StatefulWidget {
  const TripRequestDetailsPage({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  final String requestId;
  final SchoolTripRequestEntity? initialRequest;

  @override
  State<TripRequestDetailsPage> createState() => _TripRequestDetailsPageState();
}

class _TripRequestDetailsPageState extends State<TripRequestDetailsPage> {
  late final TripRequestDetailsCubit _cubit;
  List<Map<String, dynamic>> _tickets = [];
  bool _loadingTickets = false;
  String? _lastLoadedRequestId;

  @override
  void initState() {
    super.initState();
    _cubit = trips_di.sl<TripRequestDetailsCubit>();
    _cubit.load(widget.requestId, optimisticRequest: widget.initialRequest);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: BlocConsumer<TripRequestDetailsCubit, TripRequestDetailsState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnackBar(context, state.errorMessage!, isError: true);
            } else if (state.successMessage != null) {
              _showSnackBar(context, state.successMessage!);
            }
          },
          builder: (context, state) {
            if (state.isLoading && !state.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }

            final request = state.request;
            if (request == null) {
              return Center(
                child: Text(
                  'trip_request_not_found'.tr(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              );
            }

            if ((request.status == TripRequestStatus.paid ||
                    request.status == TripRequestStatus.completed ||
                    request.status == TripRequestStatus.depositPaid) &&
                !_loadingTickets &&
                _lastLoadedRequestId != request.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _lastLoadedRequestId != request.id) {
                  _loadTickets(context, request.id);
                }
              });
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: RefreshIndicator(
                    color: AppColors.primaryRed,
                    onRefresh: () => _cubit.load(widget.requestId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _HeaderSection(request: request),
                          const SizedBox(height: 24),
                          _InfoSection(request: request),
                          const SizedBox(height: 24),
                          if (request.addOns.isNotEmpty) ...[
                            _AddOnsSection(request: request),
                            const SizedBox(height: 24),
                          ],
                          if (request.status == TripRequestStatus.paid ||
                              request.status ==
                                  TripRequestStatus.completed ||
                              request.status ==
                                  TripRequestStatus.depositPaid) ...[
                            _TicketsSection(
                              request: request,
                              tickets: _tickets,
                              loadingTickets: _loadingTickets,
                            ),
                            const SizedBox(height: 24),
                          ],
                          _ActionsSection(
                            request: request,
                            isSubmitting: state.isSubmitting,
                            onCancel: () => _showCancelConfirmation(context),
                            onAfterSuccessfulPayment: () async =>
                                _cubit.load(widget.requestId),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppColors.primaryRed,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_right_3, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh, color: Colors.white),
          onPressed: () => _cubit.load(widget.requestId),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'trip_request_details_title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Iconsax.warning_2 : Iconsax.tick_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppColors.errorColor
            : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loadTickets(BuildContext context, String tripRequestId) async {
    if (_loadingTickets || _lastLoadedRequestId == tripRequestId) return;
    setState(() {
      _loadingTickets = true;
      _lastLoadedRequestId = tripRequestId;
    });
    try {
      final tickets = await _cubit.getTripTickets(tripRequestId);
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _loadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTickets = false);
      }
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.errorColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'cancel_trip_request_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text('cancel_trip_request_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'no'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _cubit.cancelRequest(widget.requestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'yes_cancel'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Components
// ---------------------------------------------------------

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.request});
  final SchoolTripRequestEntity request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'school_name'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.schoolName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTimeItem(
                  icon: Iconsax.calendar_1,
                  title: 'date'.tr(),
                  value: DateFormat.yMMMMd(
                    context.locale.toString(),
                  ).format(request.preferredDate),
                ),
              ),
              if (request.preferredTime != null)
                Expanded(
                  child: _buildTimeItem(
                    icon: Iconsax.clock,
                    title: 'time'.tr(),
                    value: request.preferredTime!,
                  ),
                ),
              Expanded(
                child: _buildTimeItem(
                  icon: Iconsax.timer_1,
                  title: 'duration'.tr(),
                  value: tr(
                    'trip_duration_hours',
                    args: [request.durationHours.toString()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _statusLabel(TripRequestStatus status) {
    switch (status) {
      case TripRequestStatus.pending:
        return tr('status_pending');
      case TripRequestStatus.underReview:
        return tr('status_under_review');
      case TripRequestStatus.approved:
        return tr('trip_status_ready_for_payment');
      case TripRequestStatus.depositPaid:
        return tr('status_deposit_paid');
      case TripRequestStatus.rejected:
        return tr('status_rejected');
      case TripRequestStatus.invoiced:
        return tr('status_invoiced');
      case TripRequestStatus.paid:
        return tr('status_paid');
      case TripRequestStatus.completed:
        return tr('status_completed');
      case TripRequestStatus.cancelled:
        return tr('status_cancelled');
      case TripRequestStatus.unknown:
        return tr('status_unknown');
    }
  }
}

String _formatCurrency(double value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.request});
  final SchoolTripRequestEntity request;

  double get _computedAddOnsTotal =>
      request.addOns.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

  double get _computedTicketsTotal {
    final perStudent =
        request.pricePerStudent ?? ((request.quotedPrice ?? 0) / (request.studentsCount == 0 ? 1 : request.studentsCount));
    return perStudent * request.studentsCount;
  }

  String get _paymentOptionLabel {
    if (request.paymentOption == 'deposit') {
      return tr('trip_pay_deposit');
    }
    return tr('trip_pay_full');
  }

  @override
  Widget build(BuildContext context) {
    final remainingBalance = tripRemainingBalanceSar(request);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('trip_basic_info'.tr(), Iconsax.info_circle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Iconsax.profile_2user,
                label: 'students_count'.tr(),
                value: request.studentsCount.toString(),
              ),
              _buildDivider(),
              _InfoRow(
                icon: Iconsax.wallet_1,
                label: 'trip_payment_option'.tr(),
                value: _paymentOptionLabel,
              ),
              if (request.pricePerStudent != null) ...[
                _buildDivider(),
                _InfoRow(
                  icon: Iconsax.tag,
                  label: 'trip_price_per_student'.tr(),
                  value:
                      '${_formatCurrency(request.pricePerStudent!)} ${'currency'.tr()}',
                ),
              ],
              _buildDivider(),
              _InfoRow(
                icon: Iconsax.receipt_2,
                label: 'trip_tickets_total'.tr(),
                value:
                    '${_formatCurrency(request.ticketsTotal ?? _computedTicketsTotal)} ${'currency'.tr()}',
              ),
              _buildDivider(),
              _InfoRow(
                icon: Iconsax.box,
                label: 'trip_addons_total'.tr(),
                value:
                    '${_formatCurrency(request.addOnsTotal ?? _computedAddOnsTotal)} ${'currency'.tr()}',
              ),
              _buildDivider(),
              _InfoRow(
                icon: Iconsax.money_recive,
                label: 'trip_grand_total'.tr(),
                value:
                    '${_formatCurrency(request.totalPrice ?? request.quotedPrice ?? (_computedTicketsTotal + _computedAddOnsTotal))} ${'currency'.tr()}',
              ),
              if (request.paymentOption == 'deposit' || request.depositAmount != null) ...[
                _buildDivider(),
                  _InfoRow(
                    icon: Iconsax.card,
                    label: 'trip_deposit'.tr(),
                    value:
                        '${_formatCurrency(request.depositAmount ?? ((request.totalPrice ?? request.quotedPrice ?? (_computedTicketsTotal + _computedAddOnsTotal)) * 0.2))} ${'currency'.tr()}',
                  ),
                  if (remainingBalance > 0) ...[
                    _buildDivider(),
                    _InfoRow(
                      icon: Iconsax.wallet_add,
                      label: 'trip_remaining_balance'.tr(),
                      value:
                          '${_formatCurrency(remainingBalance)} ${'currency'.tr()}',
                    ),
                  ],
                ],
              if (request.specialRequirements != null &&
                  request.specialRequirements!.isNotEmpty) ...[
                _buildDivider(),
                _InfoRow(
                  icon: Iconsax.note_text,
                  label: 'special_requirements'.tr(),
                  value: request.specialRequirements!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
    );
  }
}

class _AddOnsSection extends StatelessWidget {
  const _AddOnsSection({required this.request});
  final SchoolTripRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final addOns = request.addOns;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        iconColor: AppColors.primaryRed,
        collapsedIconColor: AppColors.textSecondary,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.box,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'trip_addons'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, right: 44, left: 44),
          child: Text(
            tr('addons_count', args: [addOns.length.toString()]),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: addOns.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.withOpacity(0.1)),
            itemBuilder: (context, index) {
              final addon = addOns[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.star,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addon.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(
                              'addon_details',
                              args: [
                                addon.quantity.toString(),
                                addon.price.toString(),
                              ],
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.request,
    required this.isSubmitting,
    required this.onCancel,
    this.onAfterSuccessfulPayment,
  });

  final SchoolTripRequestEntity request;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final Future<void> Function()? onAfterSuccessfulPayment;

  double? get payableAmount {
    final v = tripPayableAmountSar(request);
    if (v <= 0) return null;
    return v;
  }

  String get payableAmountLabel => tripPayableAmountLabel(request);

  bool get canCancel =>
      request.status == TripRequestStatus.pending ||
      request.status == TripRequestStatus.underReview ||
      request.status == TripRequestStatus.approved;

  @override
  Widget build(BuildContext context) {
    if (request.status == TripRequestStatus.rejected ||
        request.status == TripRequestStatus.paid ||
        request.status == TripRequestStatus.completed ||
        request.status == TripRequestStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (request.status == TripRequestStatus.depositPaid) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Iconsax.info_circle,
                  color: AppColors.primaryRed,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'trip_remaining_pay_at_branch'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if ((request.status == TripRequestStatus.approved ||
                request.status == TripRequestStatus.invoiced) &&
            payableAmount != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.luxuryRedGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.luxuryDeepRed.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.wallet_1, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'trip_payment_section_title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  payableAmountLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatCurrency(payableAmount!)} ${'currency'.tr()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentMethodDialog(
                    context,
                    request,
                    onAfterSuccessfulPayment,
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.luxuryDeepRed,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Iconsax.card),
                  label: Text(
                    'pay_now'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (canCancel) ...[
          const SizedBox(height: 16),
          _buildActionButton(
            onPressed: isSubmitting ? () {} : onCancel,
            icon: Iconsax.close_circle,
            label: 'cancel_trip_request'.tr(),
            isOutlined: true,
            customColor: AppColors.errorColor,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
    bool isOutlined = false,
    bool isDisabled = false,
    Color? customColor,
  }) {
    final color = customColor ?? AppColors.primaryRed;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? color.withOpacity(0.4) : color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isDisabled ? 0 : 4,
        shadowColor: color.withOpacity(0.4),
      ),
    );
  }

  void _showPaymentMethodDialog(
    BuildContext context,
    SchoolTripRequestEntity request,
    Future<void> Function()? onAfterSuccessfulPayment,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'select_payment_method'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.card, color: Colors.blue),
                ),
                title: Text(
                  'credit_card'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _processPayment(
                    context,
                    request,
                    'credit_card',
                    onAfterSuccessfulPayment,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.wallet_1, color: Colors.green),
                ),
                title: Text(
                  'wallet'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _processPayment(
                    context,
                    request,
                    'wallet',
                    onAfterSuccessfulPayment,
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(
    BuildContext context,
    SchoolTripRequestEntity request,
    String method,
    Future<void> Function()? onAfterSuccessfulPayment,
  ) {
    try {
      payments_di.initPayments();
    } catch (_) {}

    final paymentCubit = payments_di.sl<PaymentCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: paymentCubit,
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listener: (ctx, state) async {
            if (state is PaymentIntentCreated) {
              final redirect = state.intent.redirectUrl;
              if (redirect != null && redirect.isNotEmpty) {
                final url = Uri.parse(redirect);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } else if (method == 'credit_card') {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!context.mounted) return;
                  final payable =
                      state.intent.amount ?? tripPayableAmountSar(request);
                  final paid = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => TripRequestMoyasarPaymentPage(
                        tripRequestId: request.id,
                        paymentId: state.intent.paymentId,
                        amount: payable,
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  if (paid == true) {
                    await onAfterSuccessfulPayment?.call();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('payment_success'.tr()),
                        backgroundColor: AppColors.successColor,
                      ),
                    );
                  }
                });
              }
            } else if (state is PaymentSuccess) {
              Navigator.pop(dialogContext);
              await onAfterSuccessfulPayment?.call();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('payment_success'.tr()),
                  backgroundColor: AppColors.successColor,
                ),
              );
            } else if (state is PaymentFailure) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            }
          },
          builder: (ctx, state) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: AppColors.primaryRed),
                  const SizedBox(height: 24),
                  Text(
                    state is PaymentLoading
                        ? 'processing_payment'.tr()
                        : state is PaymentIntentCreated
                        ? 'waiting_for_payment'.tr()
                        : 'please_wait'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );

    paymentCubit.payForTripRequest(
      tripRequestId: request.id,
      amount: tripPayableAmountSar(request),
      method: method,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketsSection extends StatelessWidget {
  const _TicketsSection({
    required this.request,
    required this.tickets,
    required this.loadingTickets,
  });

  final SchoolTripRequestEntity request;
  final List<Map<String, dynamic>> tickets;
  final bool loadingTickets;

  @override
  Widget build(BuildContext context) {
    final ticketsDataSource = TicketsRemoteDataSourceImpl(
      dio: DioClient.instance,
    );

    if (request.status != TripRequestStatus.paid &&
        request.status != TripRequestStatus.completed &&
        request.status != TripRequestStatus.depositPaid) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.ticket,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'tickets'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loadingTickets)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          )
        else if (tickets.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'no_tickets'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final ticketId = ticket['id']?.toString() ?? '';
              final status =
                  ticket['status']?.toString().toLowerCase() ?? 'valid';
              final validFrom = ticket['validFrom'] != null
                  ? DateTime.tryParse(ticket['validFrom'].toString())
                  : null;
              final validUntil = ticket['validUntil'] != null
                  ? DateTime.tryParse(ticket['validUntil'].toString())
                  : null;
              final createdAt = ticket['createdAt'] != null
                  ? DateTime.tryParse(ticket['createdAt'].toString())
                  : null;
              final holderName = ticket['holderName']?.toString();

              return ModernTicketWidget(
                ticketId: ticketId,
                status: status,
                personNumber: index + 1,
                totalPersons: tickets.length,
                holderName: holderName,
                validFrom: validFrom,
                validUntil: validUntil,
                createdAt: createdAt,
                onViewQr: () async {
                  try {
                    final qr = await ticketsDataSource.getTicketQr(ticketId);
                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'qr_code'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: qr.startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(qr.split(',').last),
                                      )
                                    : SelectableText(qr),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      HapticFeedback.selectionClick();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('share'.tr())),
                                      );
                                      await shareTicketQrPreferWhatsApp(
                                        context: context,
                                        ticketId: ticketId,
                                        qrData: qr,
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('unknown_error'.tr()),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Iconsax.share,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'share'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
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
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('unknown_error'.tr())),
                    );
                  }
                },
              );
            },
          ),
      ],
    );
  }
}
