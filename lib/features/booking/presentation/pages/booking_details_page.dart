// Booking Details Page - Presentation Layer
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/booking_entity.dart';
import 'package:get_it/get_it.dart';
import '../widgets/price_breakdown_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/entities/quote_entity.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../tickets/data/datasources/tickets_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';
import '../../../tickets/data/models/ticket_model.dart';
import 'package:dio/dio.dart';
import '../../../activities/data/bookings_api.dart';
import '../widgets/modern_ticket_widget.dart';
import '../../../../core/utils/share_utils.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../di/booking_injection.dart';

class BookingDetailsPage extends StatefulWidget {
  final BookingEntity booking;
  final QuoteEntity? quote; // للعرض التفصيلي للسعر
  final Set<String>? filterTicketIds; // لتقييد العرض بمعرفات تذاكر محددة

  const BookingDetailsPage({
    super.key,
    required this.booking,
    this.quote,
    this.filterTicketIds,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with WidgetsBindingObserver {
  QuoteEntity? _quote;
  BookingEntity? _currentBooking; // الحجز الحالي المعروض
  bool _isLoadingQuote = false;
  String? _quoteError;
  late final BookingCubit _bookingCubit;
  Timer? _paymentStatusTimer; // Timer للتحقق الدوري من حالة الدفع

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // تسجيل المراقب
    _currentBooking = widget.booking;
    _quote = widget.quote;
    _bookingCubit = sl<BookingCubit>();
    // إذا لم يكن هناك quote، نحاول جلبها بعد تهيئة الواجهة
    if (_quote == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadQuote();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // إزالة المراقب
    // إلغاء Timer عند إغلاق الصفحة
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;
    // لا نحذف BookingCubit لأنه مسجل كـ factory في GetIt
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند العودة للتطبيق (resumed) نحاول تحديث حالة الحجز
    // هذا مفيد عند العودة من عملية الدفع في المتصفح
    if (state == AppLifecycleState.resumed) {
      _refreshBookingDetails();
    }
  }

  Future<void> _refreshBookingDetails() async {
    try {
      // جلب بيانات الحجز المحدثة
      final updatedBooking = await BookingsApi().getBookingById(
        widget.booking.id,
      );
      if (mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });

        // إذا تغيرت الحالة إلى مدفوع، نعرض رسالة نجاح
        if (widget.booking.status.toLowerCase() != 'confirmed' &&
            updatedBooking.status.toLowerCase() == 'confirmed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('payment_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
    }
  }

  Future<void> _loadQuote() async {
    if (_isLoadingQuote) return;

    final isPast = _currentBooking!.startTime.isBefore(DateTime.now());
    final isConfirmed = _currentBooking!.status.toLowerCase() == 'confirmed';
    if (isPast && isConfirmed) {
      // لا حاجة لجلب تفاصيل السعر لحجز مؤكد في الماضي، سيتم عرض البديل تلقائياً
      return;
    }

    setState(() {
      _isLoadingQuote = true;
    });

    try {
      await _bookingCubit.getQuote(
        branchId: _currentBooking!.branchId,
        startTime: _currentBooking!.startTime,
        durationHours: _currentBooking!.durationHours,
        persons: _currentBooking!.persons,
        addOns: null, // BookingEntity لا يحتوي على addOns
        couponCode: _currentBooking!.couponCode,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQuote = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('booking_details'.tr()),
        centerTitle: true,
        actions: [
          // زر المشاركة
          IconButton(
            icon: const Icon(Iconsax.share),
            onPressed: () async {
              // مشاركة مختصرة لتفاصيل الحجز
              final msg =
                  '${'booking_details'.tr()} - ${'hall'.tr()}: ${'hall'.tr()} | ${'date_time'.tr()}: ${DateFormat('yyyy-MM-dd HH:mm').format(_currentBooking!.startTime)} | ${'duration'.tr()}: ${_currentBooking!.durationHours} ${'hours'.tr()}';
              try {
                await Share.share(msg);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('unknown_error'.tr())));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الحجز الأساسية
            _buildBookingInfoCard(context, _currentBooking!),
            const SizedBox(height: 16),

            // حالة الحجز
            _buildStatusCard(context, _currentBooking!),
            const SizedBox(height: 16),

            // تفاصيل التسعير
            BlocProvider.value(
              value: _bookingCubit,
              child: BlocConsumer<BookingCubit, BookingState>(
                listener: (context, state) {
                  // تحديث الـ state المحلي عند تغيير الـ state
                  if (state is QuoteLoaded) {
                    if (mounted && _quote != state.quote) {
                      setState(() {
                        _quote = state.quote;
                        _isLoadingQuote = false;
                      });
                    }
                  } else if (state is QuoteError) {
                    if (mounted) {
                      setState(() {
                        _isLoadingQuote = false;
                        _quoteError = state.message;
                      });
                    }
                  }
                },
                builder: (context, state) {
                  // استخدام الـ state من BlocBuilder مباشرة
                  QuoteEntity? displayQuote = _quote;
                  bool displayIsLoading = _isLoadingQuote;
                  String? displayError = _quoteError;

                  if (state is QuoteLoaded) {
                    displayQuote = state.quote;
                    displayIsLoading = false;
                    displayError = null;
                    // مسح رسالة الخطأ عند نجاح الجلب
                    if (_quoteError != null) {
                      _quoteError = null;
                    }
                  } else if (state is QuoteLoading) {
                    displayIsLoading = true;
                    displayError = null;
                  } else if (state is QuoteError) {
                    displayIsLoading = false;
                    displayError = state.message;
                    // تحديث _quoteError في الـ state المحلي
                    if (_quoteError != state.message) {
                      _quoteError = state.message;
                    }
                  }

                  final bool isPast = _currentBooking!.startTime.isBefore(
                    DateTime.now(),
                  );
                  final bool isConfirmed =
                      _currentBooking!.status.toLowerCase() == 'confirmed';
                  // نعرض السعر الإجمالي كبديل إذا كان هناك خطأ، أو إذا كان الحجز في الماضي ومؤكداً
                  final bool forceFallback = isPast && isConfirmed;

                  // إذا كان هناك خطأ أو فرضنا البديل، نعرض السعر الإجمالي من الحجز
                  if ((forceFallback ||
                          (displayError != null && displayError.isNotEmpty)) &&
                      displayQuote == null) {
                    final bool showErrorMessage =
                        displayError != null &&
                        displayError.isNotEmpty &&
                        !isConfirmed;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Iconsax.dollar_circle, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'price_breakdown'.tr(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // رسالة الخطأ (تُخفى للحجوزات المؤكدة)
                            if (showErrorMessage) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.info_circle,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        displayError,
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // عرض السعر الإجمالي من الحجز كبديل
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'total_price'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_currentBooking!.totalPrice.toStringAsFixed(2)} ${'currency'.tr()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryRed,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return PriceBreakdownCard(
                    quote: displayQuote,
                    isLoading: displayIsLoading,
                    durationHours: _currentBooking!.durationHours,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // معلومات إضافية
            _buildAdditionalInfoCard(context, _currentBooking!),
            const SizedBox(height: 16),

            // التذاكر الخاصة بهذا الحجز فقط
            _buildTicketsSection(
              context,
              _currentBooking!,
              widget.filterTicketIds,
            ),
            const SizedBox(height: 16),

            // أزرار الإجراءات
            _buildActionButtons(context, _currentBooking!),
            const SizedBox(height: 16),

            // إظهار ملاحظة عدم إتاحة التذاكر قبل الدفع
            if (_currentBooking!.status.toLowerCase() == 'pending')
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Iconsax.info_circle, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'complete_payment_to_view_tickets'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.orange.shade800),
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

  Widget _buildBookingInfoCard(BuildContext context, BookingEntity booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.calendar, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'booking_information'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // اسم القاعة
            _buildInfoRow(
              context,
              'hall'.tr(),
              'hall'.tr(), // TODO: إضافة اسم القاعة من البيانات
              Iconsax.home_2,
            ),
            const SizedBox(height: 8),

            // التاريخ والوقت
            _buildInfoRow(
              context,
              'date_time'.tr(),
              DateFormat('yyyy-MM-dd HH:mm').format(booking.startTime),
              Iconsax.calendar,
            ),
            const SizedBox(height: 8),

            // المدة
            _buildInfoRow(
              context,
              'duration'.tr(),
              '${booking.durationHours} ${'hours'.tr()}',
              Iconsax.timer,
            ),
            const SizedBox(height: 8),

            // عدد الأشخاص
            _buildInfoRow(
              context,
              'number_of_persons'.tr(),
              '${booking.persons} ${'persons'.tr()}',
              Iconsax.people,
            ),
            const SizedBox(height: 8),

            // السعر الإجمالي
            _buildInfoRow(
              context,
              'total_price'.tr(),
              '${booking.totalPrice.toStringAsFixed(2)} ${'currency'.tr()}',
              Iconsax.dollar_circle,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, BookingEntity booking) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (booking.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Iconsax.clock;
        statusText = 'pending'.tr();
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Iconsax.tick_circle;
        statusText = 'confirmed'.tr();
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Iconsax.close_circle;
        statusText = 'cancelled'.tr();
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Iconsax.info_circle;
        statusText = booking.status;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'booking_status'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (booking.status.toLowerCase() == 'cancelled' &&
                booking.cancellationReason != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Iconsax.info_circle, color: Colors.grey.shade600),
                onPressed: () {
                  _showCancellationReason(context, booking);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BuildContext context, BookingEntity booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.document_text, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'additional_information'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // كود الخصم
            if (booking.couponCode != null) ...[
              _buildInfoRow(
                context,
                'coupon_code'.tr(),
                booking.couponCode!,
                Iconsax.discount_shape,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
            ],

            // مبلغ الخصم
            if (booking.discountAmount != null &&
                booking.discountAmount! > 0) ...[
              _buildInfoRow(
                context,
                'discount_amount'.tr(),
                '${booking.discountAmount!.toStringAsFixed(2)} ${'currency'.tr()}',
                Iconsax.discount_shape,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
            ],

            // الطلبات الخاصة
            if (booking.specialRequests != null &&
                booking.specialRequests!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                'special_requests'.tr(),
                booking.specialRequests!,
                Iconsax.message_text,
              ),
              const SizedBox(height: 8),
            ],

            // رقم الهاتف
            if (booking.contactPhone != null &&
                booking.contactPhone!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                'contact_phone'.tr(),
                booking.contactPhone!,
                Iconsax.call,
              ),
              const SizedBox(height: 8),
            ],

            // تاريخ الإنشاء
            _buildInfoRow(
              context,
              'created_at'.tr(),
              DateFormat('yyyy-MM-dd HH:mm').format(booking.createdAt),
              Iconsax.calendar_1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingEntity booking) {
    return Column(
      children: [
        // لم نعد ننتقل لصفحة عامة؛ نعرض التذاكر هنا مباشرة
        // زر الإلغاء (إذا كان الحجز قابل للإلغاء)
        if (booking.status.toLowerCase() == 'pending') ...[
          // زر الدفع الآن مع اختيار طريقة الدفع
          CustomButton(
            onPressed: () => _showPaymentMethodDialog(context),
            icon: const Icon(Iconsax.card, color: Colors.white, size: 20),
            text: 'pay_now',
            useGradient: true,
          ),
          const SizedBox(height: 12),
          CustomButton(
            onPressed: () {
              // إذا كان الحجز pending (غير مدفوع)، السماح بالإلغاء بدون قيود
              final isUnpaid =
                  _currentBooking!.status.toLowerCase() == 'pending';

              if (!isUnpaid) {
                // للحجوزات المدفوعة (confirmed)، تطبيق قيد 24 ساعة
                final now = DateTime.now();
                final hoursUntil = _currentBooking!.startTime
                    .difference(now)
                    .inHours;
                if (hoursUntil < 24) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        // رسالة عربية واضحة لحالة أقل من 24 ساعة
                        'cannot_cancel_before_24h'.tr(),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
              }
              _showCancelBookingDialog(context);
            },
            icon: const Icon(
              Iconsax.close_circle,
              color: Colors.white,
              size: 20,
            ),
            text: 'cancel_booking',
            useGradient: false,
            backgroundColor: AppColors.errorColor,
          ),
          const SizedBox(height: 12),
        ],

        // زر العودة
        CustomOutlinedButton(
          onPressed: () => Navigator.pop(context),
          text: 'back',
          icon: const Icon(Iconsax.arrow_left, size: 20),
        ),
      ],
    );
  }

  Widget _buildTicketsSection(
    BuildContext context,
    BookingEntity booking,
    Set<String>? filterTicketIds,
  ) {
    // عرض تذاكر هذا الحجز فقط
    final ds = TicketsRemoteDataSourceImpl(dio: DioClient.instance);
    final Future<List<TicketModel>> ticketsFuture = ds.getBookingTickets(
      booking.id,
    );

    if (booking.status.toLowerCase() == 'pending') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple Section Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Iconsax.ticket5,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'tickets'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'tap_to_view_qr'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<TicketModel>>(
          future: ticketsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              // Simple Skeleton Loader
              return Column(
                children: List.generate(
                  2,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  height: 16,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  height: 12,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  height: 12,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
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
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            final tickets = snapshot.data ?? const <TicketModel>[];

            // Filter tickets strictly by provided ticket IDs (if any)
            List<TicketModel> myTickets;
            if (filterTicketIds != null && filterTicketIds.isNotEmpty) {
              myTickets = tickets
                  .where((t) => filterTicketIds.contains(t.id))
                  .toList();
            } else {
              myTickets = tickets; // عرض كل تذاكر الحجز افتراضيًا
            }

            if (myTickets.isEmpty) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Icon(Iconsax.ticket, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'no_tickets'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            }
            final countText = '${'tickets'.tr()} (${myTickets.length})';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    countText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myTickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = myTickets[index];
                    return ModernTicketWidget(
                      ticketId: t.id,
                      status: t.status,
                      personNumber: index + 1,
                      totalPersons: myTickets.length,
                      holderName: t.holderName,
                      holderPhone: t.holderPhone,
                      validFrom: t.validFrom,
                      validUntil: t.validUntil,
                      createdAt: t.createdAt,
                      onViewQr: () async {
                        final qr = await ds.getTicketQr(t.id);
                        if (!context.mounted) return;
                        _showQrBottomSheet(context, qr, t.id);
                      },
                      onCopyId: () async {
                        await Clipboard.setData(ClipboardData(text: t.id));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('copied'.tr())));
                      },
                      onShare: () async {
                        try {
                          HapticFeedback.selectionClick();
                          final qr = await ds.getTicketQr(t.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('share'.tr())));
                          await shareTicketQrPreferWhatsApp(
                            context: context,
                            ticketId: t.id,
                            qrData: qr,
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
          },
        ),
      ],
    );
  }

  void _showQrBottomSheet(
    BuildContext context,
    String qrData,
    String ticketId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.scan_barcode),
                  const SizedBox(width: 8),
                  Text(
                    'qr_code'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(child: _buildQrWidget(qrData)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('share'.tr())));
                      await shareTicketQrPreferWhatsApp(
                        context: context,
                        ticketId: ticketId,
                        qrData: qrData,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('unknown_error'.tr())),
                      );
                    }
                  },
                  icon: const Icon(Iconsax.export_1),
                  label: Text('share'.tr()),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'do_not_share_qr_warning'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  // عنصر بسيط لعرض QR إما Data URL صورة أو نص
  // يستخدم محليًا لعرض QR ضمن تفاصيل الحجز
  Widget _buildQrWidget(String data) {
    if (data.startsWith('data:image')) {
      try {
        final payload = data.split(',').last;
        return Image.memory(
          base64Decode(payload),
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      } catch (_) {
        return SelectableText(data);
      }
    }
    return SelectableText(data);
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Colors.grey.shade700,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showCancellationReason(BuildContext context, BookingEntity booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cancellation_reason'.tr()),
        content: Text(booking.cancellationReason ?? 'no_reason_provided'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodDialog(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;
    final walletBalance = user?.wallet?.balance ?? 0.0;
    final hasEnoughBalance = walletBalance >= _currentBooking!.totalPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_payment_method'.tr()),
        content: BlocProvider(
          create: (_) {
            final cubit = GetIt.instance<WalletCubit>();
            if (cubit.state is WalletInitial) {
              cubit.loadWallet();
            }
            return cubit;
          },
          child: BlocBuilder<WalletCubit, WalletState>(
            builder: (context, walletState) {
              double currentBalance = walletBalance;
              bool currentHasEnoughBalance = hasEnoughBalance;

              if (walletState is WalletLoaded) {
                currentBalance = walletState.wallet.balance;
                currentHasEnoughBalance =
                    currentBalance >= _currentBooking!.totalPrice;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Credit Card / Visa / Mastercard
                  ListTile(
                    leading: const Icon(Iconsax.card, color: Colors.blue),
                    title: Text('credit_card'.tr()),
                    subtitle: Text('visa_mastercard'.tr()),
                    trailing: const Icon(Iconsax.arrow_left_2),
                    onTap: () {
                      Navigator.pop(context);
                      _processPayment(context, 'credit_card');
                    },
                  ),
                  const Divider(),
                  // Mada (مدى)
                  ListTile(
                    leading: const Icon(Iconsax.card, color: Colors.green),
                    title: Text('mada'.tr()),
                    subtitle: Text('mada_card'.tr()),
                    trailing: const Icon(Iconsax.arrow_left_2),
                    onTap: () {
                      Navigator.pop(context);
                      _processPayment(context, 'mada');
                    },
                  ),
                  const Divider(),
                  // Wallet
                  ListTile(
                    leading: const Icon(Iconsax.wallet_3, color: Colors.green),
                    title: Text('pay_with_wallet'.tr()),
                    subtitle: currentHasEnoughBalance
                        ? Text(
                            '${'wallet_balance'.tr()}: ${currentBalance.toStringAsFixed(2)} ${'currency'.tr()}',
                          )
                        : Text(
                            'insufficient_balance'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                    trailing: currentHasEnoughBalance
                        ? const Icon(Iconsax.arrow_left_2)
                        : const Icon(Iconsax.info_circle, color: Colors.red),
                    enabled: currentHasEnoughBalance,
                    onTap: currentHasEnoughBalance
                        ? () {
                            Navigator.pop(context);
                            _processPayment(context, 'wallet');
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );

    // Load wallet balance
    if (GetIt.instance<WalletCubit>().state is WalletInitial) {
      GetIt.instance<WalletCubit>().loadWallet();
    }
  }

  void _processPayment(BuildContext context, String method) {
    try {
      payments_di.initPayments();
    } catch (_) {}

    final paymentCubit = payments_di.sl<PaymentCubit>();
    // حفظ context الصفحة الأصلية للعودة إليها بعد الدفع
    final pageContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: paymentCubit,
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listener: (dialogContext, state) async {
            if (state is PaymentIntentCreated) {
              // تم فتح صفحة الدفع - نعرض رسالة للمستخدم
              Navigator.pop(dialogContext); // Close loading dialog

              if (pageContext.mounted) {
                // إظهار رسالة للمستخدم
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text('complete_payment_open_page'.tr()),
                    duration: const Duration(seconds: 5),
                    backgroundColor: Colors.blue,
                    action: SnackBarAction(
                      label: 'verify_status'.tr(),
                      textColor: Colors.white,
                      onPressed: () {
                        // التحقق من حالة الدفع عند الضغط على الزر
                        paymentCubit.checkPaymentStatus(
                          bookingId: widget.booking.id,
                          paymentId: state.intent.paymentId,
                          chargeId: state.intent.chargeId,
                        );
                      },
                    ),
                  ),
                );

                // بدء التحقق الدوري من حالة الدفع (كل 10 ثوان)
                _paymentStatusTimer?.cancel(); // إلغاء أي timer سابق
                _paymentStatusTimer = Timer.periodic(
                  const Duration(seconds: 10),
                  (timer) async {
                    if (!pageContext.mounted) {
                      timer.cancel();
                      return;
                    }

                    // التحقق من حالة الدفع
                    paymentCubit.checkPaymentStatus(
                      bookingId: widget.booking.id,
                      paymentId: state.intent.paymentId,
                      chargeId: state.intent.chargeId,
                    );

                    // إيقاف التحقق بعد 5 دقائق
                    if (timer.tick >= 30) {
                      timer.cancel();
                      _paymentStatusTimer = null;
                    }
                  },
                );
              }
            } else if (state is PaymentSuccess) {
              // إلغاء Timer عند نجاح الدفع
              _paymentStatusTimer?.cancel();
              _paymentStatusTimer = null;

              Navigator.pop(dialogContext); // Close loading dialog

              // إظهار رسالة النجاح
              if (pageContext.mounted) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text('payment_success'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
              }

              // جلب بيانات الحجز المحدثة من الخادم
              try {
                // إضافة تأخير بسيط لضمان تحديث البيانات في الخادم
                await Future.delayed(const Duration(milliseconds: 500));

                if (!pageContext.mounted) return;

                // جلب بيانات الحجز المحدثة
                final updatedBooking = await BookingsApi().getBookingById(
                  widget.booking.id,
                );

                if (!pageContext.mounted) return;

                // إغلاق الصفحة الحالية والانتقال إلى صفحة تفاصيل الحجز المحدثة
                Navigator.of(pageContext).pop(); // إغلاق الصفحة الحالية

                if (!pageContext.mounted) return;

                // الانتقال إلى صفحة تفاصيل الحجز المحدثة
                Navigator.of(pageContext).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => BookingDetailsPage(
                      booking: updatedBooking,
                      quote: _quote,
                      filterTicketIds: widget.filterTicketIds,
                    ),
                  ),
                );
              } catch (e) {
                // في حالة فشل جلب البيانات المحدثة، العودة للصفحة السابقة
                if (!pageContext.mounted) return;
                Navigator.of(pageContext).pop(true);
              }
            } else if (state is PaymentFailure) {
              // إلغاء Timer عند فشل الدفع
              _paymentStatusTimer?.cancel();
              _paymentStatusTimer = null;

              Navigator.pop(dialogContext); // Close loading dialog
              if (pageContext.mounted) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            final isLoading = state is PaymentLoading;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('processing'.tr()),
                  ] else
                    const CircularProgressIndicator(),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Create payment intent and process
    paymentCubit.payForBooking(booking: _currentBooking!, method: method);
  }

  void _showCancelBookingDialog(BuildContext context) {
    // حفظ context الصفحة الأصلية
    final pageContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('cancel_booking'.tr()),
        content: Text('cancel_booking_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('no'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // مؤشر انتظار
              showDialog(
                context: pageContext,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                await BookingsApi().cancelBooking(id: _currentBooking!.id);
                if (!pageContext.mounted) return;
                Navigator.pop(pageContext); // اغلاق مؤشر الانتظار

                // التحقق من حالة الحجز لتحديد الرسالة المناسبة
                final isUnpaid =
                    _currentBooking!.status.toLowerCase() == 'pending';

                if (pageContext.mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        isUnpaid
                            ? 'booking_deleted_successfully'.tr()
                            : 'booking_cancelled'.tr(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                // العودة مع نتيجة true لتحديث البيانات في الصفحة السابقة
                Navigator.of(pageContext).pop(true);
              } catch (e) {
                if (!pageContext.mounted) return;
                Navigator.pop(pageContext); // اغلاق مؤشر الانتظار
                String message = e.toString();
                if (e is DioException) {
                  final data = e.response?.data;
                  if (data is Map && data['message'] is String) {
                    final serverMsg = data['message'] as String;
                    if (serverMsg.contains('24 hours')) {
                      message = 'cannot_cancel_before_24h'.tr();
                    } else {
                      message = serverMsg;
                    }
                  }
                }
                if (pageContext.mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
  }
}
