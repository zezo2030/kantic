import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../booking/presentation/pages/booking_details_page.dart';
import '../../../activities/data/bookings_api.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../cubit/payment_cubit.dart';
import '../../di/payments_injection.dart' as payments_di;
import '../../../../core/routes/app_route_generator.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String paymentId;

  const PaymentSuccessPage({super.key, required this.paymentId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  String? _bookingId;
  String? _tripRequestId;
  String? _eventRequestId;
  String? _subscriptionPurchaseId;
  String? _offerBookingId;
  bool _isLoading = true;
  String? _error;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      payments_di.initPayments();
      final paymentCubit = payments_di.sl<PaymentCubit>();

      await _getPaymentDetails();

      // التحقق من نوع الدفع واستدعاء checkPaymentStatus بالمعرف المناسب
      if (_bookingId != null && mounted) {
        paymentCubit.checkPaymentStatus(
          bookingId: _bookingId!,
          paymentId: widget.paymentId,
        );
      } else if (_tripRequestId != null && mounted) {
        paymentCubit.checkPaymentStatus(
          tripRequestId: _tripRequestId!,
          paymentId: widget.paymentId,
        );
      } else if (_eventRequestId != null && mounted) {
        paymentCubit.checkPaymentStatus(
          eventRequestId: _eventRequestId!,
          paymentId: widget.paymentId,
        );
      } else if (_subscriptionPurchaseId != null && mounted) {
        paymentCubit.checkPaymentStatus(
          subscriptionPurchaseId: _subscriptionPurchaseId!,
          paymentId: widget.paymentId,
        );
      } else if (_offerBookingId != null && mounted) {
        paymentCubit.checkPaymentStatus(
          offerBookingId: _offerBookingId!,
          paymentId: widget.paymentId,
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = 'payment_info_not_found'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'payment_info_load_error'.tr(args: [e.toString()]);
      });
    }
  }

  Future<void> _getPaymentDetails() async {
    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}/payments/${widget.paymentId}',
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> data = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      final bookingId = data['bookingId']?.toString();
      final tripRequestId = data['tripRequestId']?.toString();
      final eventRequestId = data['eventRequestId']?.toString();
      final subscriptionPurchaseId =
          data['subscriptionPurchaseId']?.toString();
      final offerBookingId = data['offerBookingId']?.toString();

      setState(() {
        _bookingId = bookingId;
        _tripRequestId = tripRequestId;
        _eventRequestId = eventRequestId;
        _subscriptionPurchaseId = subscriptionPurchaseId;
        _offerBookingId = offerBookingId;
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: payments_di.sl<PaymentCubit>(),
      child: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            setState(() {
              _isLoading = false;
              _isSuccess = true;
            });
          } else if (state is PaymentFailure) {
            setState(() {
              _isLoading = false;
              _error = state.message;
            });
          }
        },
        builder: (context, state) {
          return Scaffold(body: SafeArea(child: _buildBody(context)));
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'verifying_payment'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'payment_failed_title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[800],
                  ),
                  child: Text('back'.tr()),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSuccess) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 100,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),

              // Success Text
              Text(
                'payment_success_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${tr('transaction_id')}: ${widget.paymentId.length > 8 ? '${widget.paymentId.substring(0, 8)}...' : widget.paymentId}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Actions
              if (_bookingId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToBookingDetails,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text('view_booking'.tr()),
                  ),
                ),
              if (_subscriptionPurchaseId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.subscriptionDetails,
                      arguments: {
                        'purchaseId': _subscriptionPurchaseId!,
                      },
                    ),
                    child: Text('subscription_details'.tr()),
                  ),
                ),
              ],
              if (_offerBookingId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.offerBookingDetails,
                      arguments: {'bookingId': _offerBookingId!},
                    ),
                    child: Text('offer_booking_details'.tr()),
                  ),
                ),
              ],
              if (_tripRequestId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.schoolTripsDetails,
                      arguments: {'requestId': _tripRequestId},
                    ),
                    child: Text('school_trips'.tr()),
                  ),
                ),
              ],
              if (_eventRequestId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.main,
                    ),
                    child: Text('event_requests'.tr()),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to Home and remove all previous routes
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('back_to_home'.tr()),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _navigateToBookingDetails() async {
    if (_bookingId == null) return;

    try {
      final updatedBooking = await BookingsApi().getBookingById(_bookingId!);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsPage(booking: updatedBooking),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_load_booking_details'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
