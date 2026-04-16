// Event Request Details Page - Presentation Layer
import 'dart:async';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/share_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/event_time_slot_display.dart';
import '../../../../core/utils/wallet_amount_format.dart';
import '../../../auth/di/auth_injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../../booking/presentation/widgets/modern_ticket_widget.dart';
import '../../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../../domain/entities/event_request_entity.dart';
import '../../domain/entities/event_request_status.dart';
import '../cubit/event_request_cubit.dart';
import '../cubit/event_request_state.dart';
import '../widgets/event_request_status_badge.dart';
import 'event_request_moyasar_payment_page.dart';

class _EventRequestDetailsHelper {
  static String getEventTypeTranslation(String type) {
    switch (type) {
      case 'birthday':
        return 'event_type_birthday'.tr();
      case 'graduation':
        return 'event_type_graduation'.tr();
      case 'family':
        return 'event_type_family'.tr();
      case 'corporate':
        return 'event_type_corporate'.tr();
      case 'wedding':
        return 'event_type_wedding'.tr();
      case 'other':
        return 'event_type_other'.tr();
      default:
        return type;
    }
  }

  static Color getEventTypeColor(String type) {
    switch (type) {
      case 'birthday':
        return const Color(0xFFEC4899);
      case 'graduation':
        return const Color(0xFF8B5CF6);
      case 'family':
        return const Color(0xFF06B6D4);
      case 'corporate':
        return const Color(0xFF3B82F6);
      case 'wedding':
        return const Color(0xFFF43F5E);
      default:
        return AppColors.primaryOrange;
    }
  }

  static IconData getEventTypeIcon(String type) {
    switch (type) {
      case 'birthday':
        return Iconsax.cake;
      case 'graduation':
        return Iconsax.medal_star;
      case 'family':
        return Iconsax.home_2;
      case 'corporate':
        return Iconsax.briefcase;
      case 'wedding':
        return Iconsax.heart;
      default:
        return Iconsax.star;
    }
  }
}

class EventRequestDetailsPage extends StatefulWidget {
  final String requestId;
  final double? initialPayableAmount;
  final double? initialGrandTotal;
  final double? initialAddonsTotal;
  final String? initialPaymentOption;
  final String? initialSelectedTimeSlot;
  final bool autoStartPayment;

  const EventRequestDetailsPage({
    super.key,
    required this.requestId,
    this.initialPayableAmount,
    this.initialGrandTotal,
    this.initialAddonsTotal,
    this.initialPaymentOption,
    this.initialSelectedTimeSlot,
    this.autoStartPayment = false,
  });

  @override
  State<EventRequestDetailsPage> createState() =>
      _EventRequestDetailsPageState();
}

class _EventRequestDetailsPageState extends State<EventRequestDetailsPage>
    with WidgetsBindingObserver {
  late final EventRequestCubit _eventRequestCubit;
  Timer? _paymentStatusTimer;
  List<Map<String, dynamic>> _tickets = [];
  bool _loadingTickets = false;
  String? _lastLoadedRequestId;
  bool _didAutoStartPayment = false;

  bool _isPaymentCompletedStatus(EventRequestStatus status) {
    return status == EventRequestStatus.depositPaid ||
        status == EventRequestStatus.paid ||
        status == EventRequestStatus.confirmed;
  }

  @override
  void initState() {
    super.initState();
    _eventRequestCubit = sl<EventRequestCubit>()
      ..getRequest(widget.requestId);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentStatusTimer?.cancel();
    _eventRequestCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _eventRequestCubit.getRequest(widget.requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _eventRequestCubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.arrow_left_2,
                color: Color(0xFF1E293B),
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'event_request_details_title'.tr(),
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<EventRequestCubit, EventRequestState>(
          builder: (context, state) {
            if (state is EventRequestDetailLoading) {
              return _buildLoadingState();
            }

            if (state is EventRequestDetailError) {
              return _buildErrorState(context, state.message);
            }

            if (state is EventRequestDetailLoaded) {
              if (_isPaymentCompletedStatus(state.request.status) &&
                  !_loadingTickets &&
                  _lastLoadedRequestId != state.request.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _lastLoadedRequestId != state.request.id) {
                    _loadTickets(context, state.request.id);
                  }
                });
              }
              final initialPayableAmount = widget.initialPayableAmount;
              if (widget.autoStartPayment &&
                  !_didAutoStartPayment &&
                  initialPayableAmount != null &&
                  initialPayableAmount > 0 &&
                  !_isPaymentCompletedStatus(state.request.status)) {
                _didAutoStartPayment = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _showPaymentMethodDialog(
                    context,
                    state.request,
                    fallbackAmount: initialPayableAmount,
                  );
                });
              }
              return _buildDetails(context, state.request);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'loading_details'.tr(),
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.greyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.warning_2,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'error_loading_details'.tr(),
              style: const TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<EventRequestCubit>().getRequest(widget.requestId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryOrange, AppColors.primaryRed],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.refresh, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'retry'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTickets(BuildContext context, String eventRequestId) async {
    if (_lastLoadedRequestId == eventRequestId) return;

    setState(() {
      _loadingTickets = true;
      _lastLoadedRequestId = eventRequestId;
    });

    try {
      final cubit = context.read<EventRequestCubit>();
      final tickets = await cubit.getEventTickets(eventRequestId);
      if (mounted && _lastLoadedRequestId == eventRequestId) {
        setState(() {
          _tickets = tickets;
          _loadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted && _lastLoadedRequestId == eventRequestId) {
        setState(() {
          _loadingTickets = false;
        });
      }
    }
  }

  Widget _buildDetails(BuildContext context, EventRequestEntity request) {
    final dateFormat = DateFormat(
      'yyyy-MM-dd hh:mm a',
      context.locale.toString(),
    );
    final eventTypeColor = _EventRequestDetailsHelper.getEventTypeColor(
      request.type,
    );
    final selectedTimeSlot =
        request.selectedTimeSlot ?? widget.initialSelectedTimeSlot;
    final effectivePaymentOption = _effectivePaymentOption(request);
    final addonsSubtotal = _addonsSubtotal(request);
    final hallRental = _hallRentalForUi(request, addonsSubtotal);
    final grandTotal = _grandTotalForUi(
      request,
      hallRental: hallRental,
      addonsSubtotal: addonsSubtotal,
    );
    final payableAmount = _payableAmountForUi(request);
    final depositAmount = _depositAmountForUi(request, grandTotal);
    final remainingAmount = _remainingAmountForUi(
      request,
      grandTotal,
      depositAmount,
    );
    final showDepositBreakdown =
        effectivePaymentOption == 'deposit' ||
        (depositAmount > 0 && depositAmount < grandTotal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Type Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  eventTypeColor.withOpacity(0.08),
                  eventTypeColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: eventTypeColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: eventTypeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _EventRequestDetailsHelper.getEventTypeIcon(request.type),
                    color: eventTypeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _EventRequestDetailsHelper.getEventTypeTranslation(
                          request.type,
                        ),
                        style: const TextStyle(
                          fontFamily: 'MontserratArabic',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${request.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                EventRequestStatusBadge(status: request.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSectionHeader(
                  context,
                  icon: Iconsax.information,
                  title: 'event_request_info'.tr(),
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  context,
                  'date_time'.tr(),
                  dateFormat.format(request.startTime.toLocal()),
                  Iconsax.calendar_1,
                  const Color(0xFF8B5CF6),
                ),
                if (selectedTimeSlot != null &&
                    selectedTimeSlot.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    context,
                    'time'.tr(),
                    formatEventTimeSlotRange12h(
                      selectedTimeSlot,
                      context.locale.toString(),
                    ),
                    Iconsax.clock,
                    const Color(0xFFF59E0B),
                  ),
                ],
                const SizedBox(height: 14),
                _buildInfoRow(
                  context,
                  'duration'.tr(),
                  'duration_hours_value'.tr(
                    args: [request.durationHours.toString()],
                  ),
                  Iconsax.timer,
                  const Color(0xFF06B6D4),
                ),
                const SizedBox(height: 14),
                _buildInfoRow(
                  context,
                  'persons_count'.tr(),
                  'persons_count_value'.tr(args: [request.persons.toString()]),
                  Iconsax.people,
                  const Color(0xFF3B82F6),
                ),
                if (effectivePaymentOption != null) ...[
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    context,
                    'event_payment_option'.tr(),
                    _paymentOptionLabel(effectivePaymentOption, depositAmount),
                    Iconsax.wallet_3,
                    const Color(0xFF10B981),
                  ),
                ],
                if (request.hallId != null) ...[
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    context,
                    'hall'.tr(),
                    request.hallId!,
                    Iconsax.home,
                    const Color(0xFF10B981),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Price Card
          if (grandTotal > 0 || request.quotedPrice != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.1),
                    AppColors.primaryRed.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Iconsax.money_recive,
                      size: 24,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'price_summary'.tr(),
                          style: const TextStyle(
                            fontFamily: 'MontserratArabic',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceLine('event_hall_rental'.tr(), hallRental),
                        if (addonsSubtotal > 0) ...[
                          const SizedBox(height: 8),
                          _buildPriceLine(
                            'event_addons_total'.tr(),
                            addonsSubtotal,
                          ),
                        ],
                        if (request.quotedPrice != null &&
                            request.quotedPrice! > 0 &&
                            (request.quotedPrice! - grandTotal).abs() >
                                0.01) ...[
                          const SizedBox(height: 8),
                          _buildPriceLine(
                            'quoted_price'.tr(),
                            request.quotedPrice!,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(
                          color: AppColors.primaryOrange.withOpacity(0.15),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceLine(
                          'event_grand_total'.tr(),
                          grandTotal,
                          isEmphasized: true,
                        ),
                        if (showDepositBreakdown) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.luxuryGold.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _buildPriceLine(
                                  'event_deposit_now'.tr(),
                                  payableAmount > 0
                                      ? payableAmount
                                      : depositAmount,
                                  valueColor: AppColors.luxuryGold,
                                ),
                                const SizedBox(height: 8),
                                _buildPriceLine(
                                  'event_remaining_later'.tr(),
                                  remainingAmount,
                                  valueColor: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (grandTotal > 0 || request.quotedPrice != null)
            const SizedBox(height: 16),

          // Notes Card (if exists)
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSectionHeader(
                    context,
                    icon: Iconsax.note,
                    title: 'notes'.tr(),
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    request.notes!,
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Add-ons Card (if exists)
          if (request.addOns != null && request.addOns!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSectionHeader(
                    context,
                    icon: Iconsax.box,
                    title: 'add_ons'.tr(),
                    color: const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 14),
                  ...request.addOns!.map((addon) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Iconsax.add,
                              size: 14,
                              color: const Color(0xFFEC4899),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              addon['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'MontserratArabic',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'x${addon['quantity'] ?? 1}',
                                style: TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_addonLineTotal(addon).toStringAsFixed(2)} ${'currency'.tr()}',
                                style: const TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tickets Card (if exists)
          if (_tickets.isNotEmpty) ...[
            _buildTicketsCard(context, request),
            const SizedBox(height: 16),
          ],

          // Action Buttons based on status
          _buildActionButtons(context, request),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceLine(
    String label,
    double value, {
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: isEmphasized ? 15 : 13,
              fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            '${value.toStringAsFixed(2)} ${'currency'.tr()}',
            style: TextStyle(
              fontFamily: 'MontserratArabic',
              fontSize: isEmphasized ? 18 : 14,
              fontWeight: FontWeight.w800,
              color:
                  valueColor ??
                  (isEmphasized ? AppColors.primaryRed : const Color(0xFF1E293B)),
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, EventRequestEntity request) {
    final payableAmount = _payableAmountForUi(request);
    final grandTotal = _grandTotalForUi(
      request,
      hallRental: _hallRentalForUi(request, _addonsSubtotal(request)),
      addonsSubtotal: _addonsSubtotal(request),
    );
    final isDepositFlow = _isDepositFlow(request);
    final remainingAmount = _remainingAmountForUi(
      request,
      grandTotal,
      _depositAmountForUi(request, grandTotal),
    );

    if (payableAmount > 0 && !_isPaymentCompletedStatus(request.status)) {
      return Column(
        children: [
          // Pay Now Button
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              _showPaymentMethodDialog(
                context,
                request,
                fallbackAmount: payableAmount,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.primaryOrange, AppColors.primaryRed],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.wallet_3, size: 22, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    isDepositFlow ? 'event_deposit_now'.tr() : 'pay_now'.tr(),
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Contact Us Button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Iconsax.call, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text('contact_us_phone'.tr())),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.luxuryBorderRose, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.call, size: 20, color: AppColors.primaryRed),
                  const SizedBox(width: 10),
                  Text(
                    'contact_us'.tr(),
                    style: TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (request.status == EventRequestStatus.depositPaid ||
        request.status == EventRequestStatus.paid) {
      final depositSubtitle = remainingAmount > 0
          ? '${'event_remaining_later'.tr()}: ${remainingAmount.toStringAsFixed(2)} ${'currency'.tr()}'
          : 'payment_received_wait_confirm'.tr();
      return _buildStatusCard(
        context,
        icon: Iconsax.clock,
        iconColor: const Color(0xFF3B82F6),
        backgroundColor: const Color(0xFFEFF6FF),
        title: isDepositFlow
            ? 'status_deposit_paid'.tr()
            : 'waiting_confirmation'.tr(),
        subtitle: isDepositFlow
            ? depositSubtitle
            : 'payment_received_wait_confirm'.tr(),
        titleColor: const Color(0xFF1D4ED8),
        subtitleColor: const Color(0xFF3B82F6),
      );
    }

    if (request.status == EventRequestStatus.confirmed) {
      return _buildStatusCard(
        context,
        icon: Iconsax.tick_circle,
        iconColor: AppColors.successColor,
        backgroundColor: const Color(0xFFDCFCE7),
        title: 'confirmed'.tr(),
        subtitle: 'event_confirmed_success'.tr(),
        titleColor: const Color(0xFF15803D),
        subtitleColor: const Color(0xFF22C55E),
      );
    }

    if (request.status == EventRequestStatus.rejected) {
      return _buildStatusCard(
        context,
        icon: Iconsax.close_circle,
        iconColor: Colors.red.shade700,
        backgroundColor: Colors.red.shade50,
        title: 'request_rejected'.tr(),
        subtitle: 'request_rejected_create_new'.tr(),
        titleColor: Colors.red.shade700,
        subtitleColor: Colors.red.shade600,
      );
    }

    if (request.status == EventRequestStatus.submitted ||
        request.status == EventRequestStatus.underReview) {
      return _buildStatusCard(
        context,
        icon: Iconsax.clock,
        iconColor: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFFFEF9C3),
        title: 'under_review'.tr(),
        subtitle: 'request_under_review_quote_soon'.tr(),
        titleColor: const Color(0xFFB45309),
        subtitleColor: const Color(0xFFF59E0B),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsCard(BuildContext context, EventRequestEntity request) {
    final ticketsDataSource = TicketsRemoteDataSourceImpl(
      dio: DioClient.instance,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryOrange.withOpacity(0.08),
                AppColors.primaryRed.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.ticket,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'your_tickets'.tr(),
                style: const TextStyle(
                  fontFamily: 'MontserratArabic',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_tickets.length}',
                  style: const TextStyle(
                    fontFamily: 'MontserratArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingTickets)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...List.generate(_tickets.length, (index) {
            final ticket = _tickets[index];
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModernTicketWidget(
                ticketId: ticketId,
                status: status,
                personNumber: index + 1,
                totalPersons: _tickets.length,
                validFrom: validFrom,
                validUntil: validUntil,
                createdAt: createdAt,
                onViewQr: () async {
                  try {
                    final qr = await ticketsDataSource.getTicketQr(ticketId);
                    if (!mounted) return;

                    showDialog(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryOrange
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Iconsax.barcode,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'qr_code'.tr(),
                                        style: const TextStyle(
                                          fontFamily: 'MontserratArabic',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (qr.startsWith('data:image'))
                                  Image.memory(base64Decode(qr.split(',').last))
                                else
                                  SelectableText(
                                    qr,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      HapticFeedback.selectionClick();
                                      await shareTicketQrPreferWhatsApp(
                                        context: context,
                                        ticketId: ticketId,
                                        qrData: qr,
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${'error'.tr()}: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryOrange,
                                          AppColors.primaryRed,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Iconsax.share,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'share'.tr(),
                                          style: const TextStyle(
                                            fontFamily: 'MontserratArabic',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text(
                                    'close'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'MontserratArabic',
                                      color: AppColors.greyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('qr_load_error'.tr(args: [e.toString()])),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onCopyId: () async {
                  await Clipboard.setData(ClipboardData(text: ticketId));
                  if (!mounted) return;
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text('ticket_id_copied'.tr()),
                        ],
                      ),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                },
                onShare: () async {
                  try {
                    final qr = await ticketsDataSource.getTicketQr(ticketId);
                    if (!mounted) return;
                    await shareTicketQrPreferWhatsApp(
                      context: context,
                      ticketId: ticketId,
                      qrData: qr,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${'error'.tr()}: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  void _showPaymentMethodDialog(
    BuildContext pageContext,
    EventRequestEntity request, {
    double? fallbackAmount,
  }) {
    final payableAmount = _payableAmountForUi(request, fallbackAmount);
    if (payableAmount <= 0) return;

    final authState = pageContext.read<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;
    final walletBalance = user?.wallet?.balance ?? 0.0;
    final hasEnoughBalance = walletBalance >= payableAmount;

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
                builder: (sheetContext, walletState) {
                  double currentBalance = walletBalance;
                  bool currentHasEnoughBalance = hasEnoughBalance;

                  if (walletState is WalletLoaded) {
                    currentBalance = walletState.wallet.balance;
                    currentHasEnoughBalance = currentBalance >= payableAmount;
                  }

                  return Column(
                    children: [
                      _buildPaymentMethodTile(
                        context: sheetContext,
                        icon: Iconsax.card,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'credit_card'.tr(),
                        subtitle: 'visa_mastercard'.tr(),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _processPayment(
                            pageContext,
                            request,
                            'credit_card',
                            fallbackAmount: payableAmount,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodTile(
                        context: sheetContext,
                        icon: Iconsax.wallet_3,
                        iconColor: AppColors.luxuryGold,
                        title: 'pay_with_wallet'.tr(),
                        subtitle: currentHasEnoughBalance
                            ? '${'wallet_balance'.tr()}: ${formatWalletMoney(currentBalance, 'currency'.tr())}'
                            : 'insufficient_balance'.tr(),
                        enabled: currentHasEnoughBalance,
                        onTap: currentHasEnoughBalance
                            ? () {
                                Navigator.pop(sheetContext);
                                _processPayment(
                                  pageContext,
                                  request,
                                  'wallet',
                                  fallbackAmount: payableAmount,
                                );
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

    if (GetIt.instance<WalletCubit>().state is WalletInitial) {
      GetIt.instance<WalletCubit>().loadWallet();
    }
  }

  Widget _buildPaymentMethodTile({
    required BuildContext context,
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
            color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
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

  void _processPayment(
    BuildContext context,
    EventRequestEntity request,
    String method, {
    double? fallbackAmount,
  }) {
    try {
      payments_di.initPayments();
    } catch (_) {}

    final paymentCubit = payments_di.sl<PaymentCubit>();
    final pageContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: paymentCubit,
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listener: (dialogContext, state) {
            if (state is PaymentIntentCreated) {
              if (method == 'wallet') {
                return;
              }

              final redirect = state.intent.redirectUrl;
              if (redirect != null && redirect.isNotEmpty) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                if (pageContext.mounted) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('complete_payment_open_page'.tr()),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 5),
                      backgroundColor: const Color(0xFF3B82F6),
                      action: SnackBarAction(
                        label: 'verify_status'.tr(),
                        textColor: Colors.white,
                        onPressed: () {
                          paymentCubit.checkPaymentStatus(
                            eventRequestId: request.id,
                            paymentId: state.intent.paymentId,
                            chargeId: state.intent.chargeId,
                          );
                        },
                      ),
                    ),
                  );

                  _paymentStatusTimer?.cancel();
                  _paymentStatusTimer = Timer.periodic(
                    const Duration(seconds: 10),
                    (timer) async {
                      if (!pageContext.mounted) {
                        timer.cancel();
                        return;
                      }

                      paymentCubit.checkPaymentStatus(
                        eventRequestId: request.id,
                        paymentId: state.intent.paymentId,
                        chargeId: state.intent.chargeId,
                      );

                      if (timer.tick >= 30) {
                        timer.cancel();
                        _paymentStatusTimer = null;
                      }
                    },
                  );
                }
              } else if (method == 'credit_card') {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!pageContext.mounted) return;
                  final payable =
                      state.intent.amount ??
                      _payableAmountForUi(request, fallbackAmount);
                  final paid = await Navigator.of(pageContext).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => EventRequestMoyasarPaymentPage(
                        eventRequestId: request.id,
                        paymentId: state.intent.paymentId,
                        amount: payable,
                      ),
                    ),
                  );
                  if (!pageContext.mounted) return;
                  if (paid == true) {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text('payment_success'.tr()),
                          ],
                        ),
                        backgroundColor: AppColors.successColor,
                      ),
                    );
                    if (pageContext.mounted) {
                      setState(() {
                        _lastLoadedRequestId = null;
                        _tickets = [];
                      });
                    }
                    pageContext.read<EventRequestCubit>().getRequest(
                      request.id,
                    );
                  }
                });
              } else {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              }
            } else if (state is PaymentSuccess) {
              _paymentStatusTimer?.cancel();
              _paymentStatusTimer = null;

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              if (pageContext.mounted) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text('payment_success'.tr()),
                      ],
                    ),
                    backgroundColor: AppColors.successColor,
                  ),
                );
                setState(() {
                  _lastLoadedRequestId = null;
                  _tickets = [];
                });
                pageContext.read<EventRequestCubit>().getRequest(request.id);
              }
            } else if (state is PaymentFailure) {
              _paymentStatusTimer?.cancel();
              _paymentStatusTimer = null;

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (pageContext.mounted) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Iconsax.warning_2, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(state.message)),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'processing_payment'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'please_wait'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    paymentCubit.payForEventRequest(eventRequest: request, method: method);
  }

  double _payableAmountForUi(
    EventRequestEntity request, [
    double? fallbackAmount,
  ]) {
    if (_isDepositFlow(request)) {
      final deposit = _depositAmountForUi(request, _grandTotalForUi(request));
      if (deposit > 0) return deposit;
    }
    if (request.amountPaid != null &&
        request.totalPrice != null &&
        request.totalPrice! > request.amountPaid!) {
      final remaining = request.totalPrice! - request.amountPaid!;
      if (remaining > 0) return remaining;
    }
    if (request.quotedPrice != null && request.quotedPrice! > 0) {
      return request.quotedPrice!;
    }
    final initial = fallbackAmount ?? widget.initialPayableAmount;
    if (initial != null && initial > 0) {
      return initial;
    }
    return 0;
  }

  String? _effectivePaymentOption(EventRequestEntity request) =>
      request.paymentOption ?? widget.initialPaymentOption;

  bool _isDepositFlow(EventRequestEntity request) =>
      _effectivePaymentOption(request) == 'deposit';

  double _addonsSubtotal(EventRequestEntity request) {
    final addOns = request.addOns;
    if (addOns == null || addOns.isEmpty) {
      return widget.initialAddonsTotal ?? 0;
    }
    return addOns.fold<double>(0, (sum, addon) => sum + _addonLineTotal(addon));
  }

  double _addonLineTotal(Map<String, dynamic> addon) {
    final price = _asDouble(addon['price']);
    final quantityRaw = addon['quantity'];
    final quantity = quantityRaw is num
        ? quantityRaw.toDouble()
        : double.tryParse(quantityRaw?.toString() ?? '') ?? 1;
    return price * quantity;
  }

  double _hallRentalForUi(EventRequestEntity request, double addonsSubtotal) {
    if (request.totalPrice != null && request.totalPrice! > addonsSubtotal) {
      return request.totalPrice! - addonsSubtotal;
    }
    if (request.quotedPrice != null && request.quotedPrice! > addonsSubtotal) {
      return request.quotedPrice! - addonsSubtotal;
    }
    final initialGrandTotal = widget.initialGrandTotal;
    if (initialGrandTotal != null && initialGrandTotal > addonsSubtotal) {
      return initialGrandTotal - addonsSubtotal;
    }
    return 200;
  }

  double _grandTotalForUi(
    EventRequestEntity request, {
    double? hallRental,
    double? addonsSubtotal,
  }) {
    if (request.totalPrice != null && request.totalPrice! > 0) {
      return request.totalPrice!;
    }
    final initialGrandTotal = widget.initialGrandTotal;
    if (initialGrandTotal != null && initialGrandTotal > 0) {
      return initialGrandTotal;
    }
    final hall =
        hallRental ?? _hallRentalForUi(request, _addonsSubtotal(request));
    final addons = addonsSubtotal ?? _addonsSubtotal(request);
    return hall + addons;
  }

  double _depositAmountForUi(EventRequestEntity request, double grandTotal) {
    if (request.depositAmount != null && request.depositAmount! > 0) {
      return request.depositAmount!;
    }
    final initialPayable = widget.initialPayableAmount;
    if (_isDepositFlow(request) &&
        initialPayable != null &&
        initialPayable > 0) {
      return initialPayable;
    }
    if (_isDepositFlow(request) && grandTotal > 0) {
      return grandTotal * 0.2;
    }
    return 0;
  }

  double _remainingAmountForUi(
    EventRequestEntity request,
    double grandTotal,
    double depositAmount,
  ) {
    if (request.remainingAmount != null && request.remainingAmount! >= 0) {
      return request.remainingAmount!;
    }
    if (request.amountPaid != null && grandTotal > request.amountPaid!) {
      return grandTotal - request.amountPaid!;
    }
    if (_isDepositFlow(request)) {
      final remaining = grandTotal - depositAmount;
      return remaining > 0 ? remaining : 0;
    }
    return 0;
  }

  String _paymentOptionLabel(String option, double depositAmount) {
    if (option == 'deposit') {
      final percent =
          widget.initialGrandTotal != null &&
              widget.initialGrandTotal! > 0 &&
              depositAmount > 0
          ? ((depositAmount / widget.initialGrandTotal!) * 100).round()
          : 20;
      return 'pay_deposit'.tr(args: [percent.toString()]);
    }
    return 'trip_pay_full'.tr();
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
