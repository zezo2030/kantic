import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../events/domain/entities/event_request_entity.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/usecases/create_payment_intent_usecase.dart';
import '../../domain/usecases/confirm_payment_usecase.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentIntentCreated extends PaymentState {
  final PaymentIntentEntity intent;
  PaymentIntentCreated(this.intent);
}

class PaymentSuccess extends PaymentState {
  final ConfirmPaymentResultEntity result;
  PaymentSuccess(this.result);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}

class PaymentCubit extends Cubit<PaymentState> {
  final CreatePaymentIntentUseCase createIntentUseCase;
  final ConfirmPaymentUseCase confirmPaymentUseCase;

  // مفاتيح Tap Payments من ملف TAP_TEST_CARDS.md
  // يجب أن يكون Public Key و Secret Key من نفس الحساب
  static const String tapPublicKey = 'pk_test_uwXLKNceB0YZfmVD8xlITM2z';
  static const String tapSecretKey = 'sk_test_f8P2NiAOd6xS4TVvICl1ryBn';
  bool _tapSessionActive = false;
  bool _paymentInProgress = false;
  Timer? _paymentStatusTimer;
  String? _currentBookingId;
  String? _currentEventRequestId;
  String? _currentTripRequestId;
  String? _currentSubscriptionPurchaseId;
  String? _currentOfferBookingId;
  String? _currentPaymentId;
  String? _currentChargeId;

  PaymentCubit({
    required this.createIntentUseCase,
    required this.confirmPaymentUseCase,
  }) : super(PaymentInitial());

  Future<void> payForBooking({
    required BookingEntity booking,
    String method = 'credit_card',
  }) async {
    if (_paymentInProgress) {
      return;
    }

    _paymentInProgress = true;
    emit(PaymentLoading());
    try {
      final intent = await createIntentUseCase(
        bookingId: booking.id,
        method: method,
      );
      emit(PaymentIntentCreated(intent));

      // If payment method is wallet, skip Tap SDK and confirm directly
      if (method == 'wallet') {
        final confirmResult = await confirmPaymentUseCase(
          bookingId: booking.id,
          paymentId: intent.paymentId,
          chargeId: intent.chargeId,
        );

        if (confirmResult.success) {
          emit(PaymentSuccess(confirmResult));
        } else {
          emit(PaymentFailure('فشل تأكيد الدفع من المحفظة'));
        }
        return;
      }

      // استخدام Tap Checkout SDK داخل التطبيق
      // نستخدم redirect URL من الباك إند إذا كان متاحاً
      if (intent.redirectUrl != null && intent.redirectUrl!.isNotEmpty) {
        // حفظ معلومات الدفع الحالية للاستخدام في polling
        _currentBookingId = booking.id;
        _currentPaymentId = intent.paymentId;
        _currentChargeId = intent.chargeId;

        await _processPaymentWithTapCheckout(
          redirectUrl: intent.redirectUrl!,
          chargeId: intent.chargeId,
          paymentId: intent.paymentId,
          bookingId: booking.id,
          amount: intent.amount ?? booking.totalPrice,
        );

        // بدء التحقق الدوري من حالة الدفع بعد بدء الدفع
        _startPaymentStatusPolling();
      } else if (intent.paymentId.isNotEmpty && method == 'credit_card') {
        // الواجهة تفتح Moyasar (بطاقة داخل التطبيق) مثل طلب الرحلة
        _paymentInProgress = false;
        return;
      } else if (intent.paymentId.isNotEmpty && method == 'credit_card') {
        _paymentInProgress = false;
        return;
      } else if (intent.paymentId.isNotEmpty) {
        emit(PaymentFailure('لم يتم الحصول على رابط الدفع'));
      } else {
        emit(PaymentFailure('لم يتم الحصول على بيانات الدفع'));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    } finally {
      if (!_tapSessionActive) {
        _paymentInProgress = false;
      }
    }
  }

  Future<void> payForEventRequest({
    required EventRequestEntity eventRequest,
    String method = 'credit_card',
  }) async {
    if (_paymentInProgress) {
      return;
    }

    _paymentInProgress = true;
    emit(PaymentLoading());
    try {
      final intent = await createIntentUseCase(
        eventRequestId: eventRequest.id,
        method: method,
      );
      emit(PaymentIntentCreated(intent));

      // If payment method is wallet, skip Tap SDK and confirm directly
      if (method == 'wallet') {
        final confirmResult = await confirmPaymentUseCase(
          eventRequestId: eventRequest.id,
          paymentId: intent.paymentId,
          chargeId: intent.chargeId,
        );

        if (confirmResult.success) {
          emit(PaymentSuccess(confirmResult));
        } else {
          emit(PaymentFailure('فشل تأكيد الدفع من المحفظة'));
        }
        return;
      }

      // استخدام Tap Checkout SDK داخل التطبيق
      // نستخدم redirect URL من الباك إند إذا كان متاحاً
      if (intent.redirectUrl != null && intent.redirectUrl!.isNotEmpty) {
        // حفظ معلومات الدفع الحالية للاستخدام في polling
        _currentEventRequestId = eventRequest.id;
        _currentPaymentId = intent.paymentId;
        _currentChargeId = intent.chargeId;

        await _processPaymentWithTapCheckout(
          redirectUrl: intent.redirectUrl!,
          chargeId: intent.chargeId,
          paymentId: intent.paymentId,
          eventRequestId: eventRequest.id,
          amount: intent.amount ?? eventRequest.quotedPrice ?? 0,
        );

        // بدء التحقق الدوري من حالة الدفع بعد بدء الدفع
        _startEventRequestPaymentStatusPolling();
      } else if (intent.paymentId.isNotEmpty && method == 'credit_card') {
        _paymentInProgress = false;
        return;
      } else if (intent.paymentId.isNotEmpty) {
        emit(PaymentFailure('لم يتم الحصول على رابط الدفع'));
      } else {
        emit(PaymentFailure('لم يتم الحصول على بيانات الدفع'));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    } finally {
      if (!_tapSessionActive) {
        _paymentInProgress = false;
      }
    }
  }

  /// دفع للرحلة المدرسية
  Future<void> payForTripRequest({
    required String tripRequestId,
    required double amount,
    String method = 'credit_card',
  }) async {
    if (_paymentInProgress) {
      return;
    }

    _paymentInProgress = true;
    emit(PaymentLoading());
    try {
      final intent = await createIntentUseCase(
        tripRequestId: tripRequestId,
        method: method,
      );
      emit(PaymentIntentCreated(intent));

      // If payment method is wallet, skip Tap SDK and confirm directly
      if (method == 'wallet') {
        final confirmResult = await confirmPaymentUseCase(
          tripRequestId: tripRequestId,
          paymentId: intent.paymentId,
          chargeId: intent.chargeId,
        );

        if (confirmResult.success) {
          emit(PaymentSuccess(confirmResult));
        } else {
          emit(PaymentFailure('فشل تأكيد الدفع من المحفظة'));
        }
        return;
      }

      // استخدام Tap Checkout عند وجود رابط؛ وإلا Moyasar داخل التطبيق (مثل شحن المحفظة)
      if (intent.redirectUrl != null && intent.redirectUrl!.isNotEmpty) {
        // حفظ معلومات الدفع الحالية للاستخدام في polling
        _currentTripRequestId = tripRequestId;
        _currentPaymentId = intent.paymentId;
        _currentChargeId = intent.chargeId;

        await _processPaymentWithTapCheckout(
          redirectUrl: intent.redirectUrl!,
          chargeId: intent.chargeId,
          paymentId: intent.paymentId,
          tripRequestId: tripRequestId,
          amount: intent.amount ?? amount,
        );

        // بدء التحقق الدوري من حالة الدفع بعد بدء الدفع
        _startTripRequestPaymentStatusPolling();
      } else if (intent.paymentId.isNotEmpty && method == 'credit_card') {
        // الباك إند لا يُرجع redirectUrl؛ الواجهة تفتح CreditCard (Moyasar) يدوياً
        _paymentInProgress = false;
        return;
      } else if (intent.paymentId.isNotEmpty) {
        emit(PaymentFailure('لم يتم الحصول على رابط الدفع'));
      } else {
        emit(PaymentFailure('لم يتم الحصول على بيانات الدفع'));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    } finally {
      if (!_tapSessionActive) {
        _paymentInProgress = false;
      }
    }
  }

  /// دفع اشتراك (بعد إنشاء subscription purchase)
  Future<void> payForSubscriptionPurchase({
    required String subscriptionPurchaseId,
    required double amount,
    String method = 'credit_card',
  }) async {
    if (_paymentInProgress) return;
    _paymentInProgress = true;
    emit(PaymentLoading());
    try {
      final intent = await createIntentUseCase(
        subscriptionPurchaseId: subscriptionPurchaseId,
        method: method,
      );
      emit(PaymentIntentCreated(intent));
      if (method == 'wallet') {
        final confirmResult = await confirmPaymentUseCase(
          subscriptionPurchaseId: subscriptionPurchaseId,
          paymentId: intent.paymentId,
          chargeId: intent.chargeId,
        );
        if (confirmResult.success) {
          emit(PaymentSuccess(confirmResult));
        } else {
          emit(PaymentFailure('فشل تأكيد الدفع من المحفظة'));
        }
        return;
      }
      if (intent.redirectUrl != null && intent.redirectUrl!.isNotEmpty) {
        _currentSubscriptionPurchaseId = subscriptionPurchaseId;
        _currentPaymentId = intent.paymentId;
        _currentChargeId = intent.chargeId;
        await _processPaymentWithTapCheckout(
          redirectUrl: intent.redirectUrl!,
          chargeId: intent.chargeId,
          paymentId: intent.paymentId,
          amount: intent.amount ?? amount,
        );
        _startSubscriptionPaymentPolling();
      } else if (intent.paymentId.isNotEmpty && method == 'credit_card') {
        _paymentInProgress = false;
        return;
      } else if (intent.paymentId.isNotEmpty) {
        emit(PaymentFailure('لم يتم الحصول على رابط الدفع'));
      } else {
        emit(PaymentFailure('لم يتم الحصول على بيانات الدفع'));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    } finally {
      if (!_tapSessionActive) {
        _paymentInProgress = false;
      }
    }
  }

  /// دفع حجز عرض منتج
  Future<void> payForOfferBooking({
    required String offerBookingId,
    required double amount,
    String method = 'credit_card',
  }) async {
    if (_paymentInProgress) return;
    _paymentInProgress = true;
    emit(PaymentLoading());
    try {
      final intent = await createIntentUseCase(
        offerBookingId: offerBookingId,
        method: method,
      );
      emit(PaymentIntentCreated(intent));
      if (method == 'wallet') {
        final confirmResult = await confirmPaymentUseCase(
          offerBookingId: offerBookingId,
          paymentId: intent.paymentId,
          chargeId: intent.chargeId,
        );
        if (confirmResult.success) {
          emit(PaymentSuccess(confirmResult));
        } else {
          emit(PaymentFailure('فشل تأكيد الدفع من المحفظة'));
        }
        return;
      }
      if (intent.redirectUrl != null && intent.redirectUrl!.isNotEmpty) {
        _currentOfferBookingId = offerBookingId;
        _currentPaymentId = intent.paymentId;
        _currentChargeId = intent.chargeId;
        await _processPaymentWithTapCheckout(
          redirectUrl: intent.redirectUrl!,
          chargeId: intent.chargeId,
          paymentId: intent.paymentId,
          amount: intent.amount ?? amount,
        );
        _startOfferBookingPaymentPolling();
      } else if (intent.paymentId.isNotEmpty) {
        emit(PaymentFailure('لم يتم الحصول على رابط الدفع'));
      } else {
        emit(PaymentFailure('لم يتم الحصول على بيانات الدفع'));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    } finally {
      if (!_tapSessionActive) {
        _paymentInProgress = false;
      }
    }
  }

  void _startSubscriptionPaymentPolling() {
    _paymentStatusTimer?.cancel();
    int attempts = 0;
    const maxAttempts = 60;
    const pollingInterval = Duration(seconds: 8);
    _paymentStatusTimer = Timer.periodic(pollingInterval, (timer) async {
      attempts++;
      if (_currentSubscriptionPurchaseId == null || _currentPaymentId == null) {
        timer.cancel();
        return;
      }
      try {
        final confirmResult = await confirmPaymentUseCase(
          subscriptionPurchaseId: _currentSubscriptionPurchaseId!,
          paymentId: _currentPaymentId!,
          chargeId: _currentChargeId,
        );
        if (confirmResult.success) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentSuccess(confirmResult));
          _currentSubscriptionPurchaseId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentFailure('انتهت مهلة التحقق من حالة الدفع'));
          _currentSubscriptionPurchaseId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentFailure('خطأ في التحقق من حالة الدفع'));
          _currentSubscriptionPurchaseId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      }
    });
  }

  void _startOfferBookingPaymentPolling() {
    _paymentStatusTimer?.cancel();
    int attempts = 0;
    const maxAttempts = 60;
    const pollingInterval = Duration(seconds: 8);
    _paymentStatusTimer = Timer.periodic(pollingInterval, (timer) async {
      attempts++;
      if (_currentOfferBookingId == null || _currentPaymentId == null) {
        timer.cancel();
        return;
      }
      try {
        final confirmResult = await confirmPaymentUseCase(
          offerBookingId: _currentOfferBookingId!,
          paymentId: _currentPaymentId!,
          chargeId: _currentChargeId,
        );
        if (confirmResult.success) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentSuccess(confirmResult));
          _currentOfferBookingId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentFailure('انتهت مهلة التحقق من حالة الدفع'));
          _currentOfferBookingId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentFailure('خطأ في التحقق من حالة الدفع'));
          _currentOfferBookingId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      }
    });
  }

  /// بدء التحقق الدوري من حالة الدفع بعد بدء الدفع
  void _startPaymentStatusPolling() {
    // إلغاء أي timer سابق
    _paymentStatusTimer?.cancel();

    int attempts = 0;
    const maxAttempts = 60; // 5 دقائق (60 * 5 ثوان)
    // زيادة الفترة بين المحاولات لتقليل الضغط على الباك إند
    const pollingInterval = Duration(seconds: 8); // 8 ثوان بدلاً من 5

    _paymentStatusTimer = Timer.periodic(pollingInterval, (timer) async {
      attempts++;

      if (_currentBookingId == null || _currentPaymentId == null) {
        timer.cancel();
        return;
      }

      try {
        final confirmResult = await confirmPaymentUseCase(
          bookingId: _currentBookingId!,
          paymentId: _currentPaymentId!,
          chargeId: _currentChargeId,
        );

        if (confirmResult.success) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentSuccess(confirmResult));

          // تنظيف
          _currentBookingId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(
            PaymentFailure(
              'انتهت مهلة التحقق من حالة الدفع. يرجى التحقق يدوياً',
            ),
          );

          // تنظيف
          _currentBookingId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      } catch (e) {

        // إذا كان الخطأ timeout، نستمر في المحاولة (قد يكون الباك إند مشغول)
        final isTimeout =
            e.toString().contains('timeout') ||
            e.toString().contains('Timeout') ||
            e.toString().contains('connection');

        if (isTimeout) {
          // نستمر في المحاولة حتى نصل للحد الأقصى
          if (attempts >= maxAttempts) {
            timer.cancel();
            _paymentStatusTimer = null;
            _tapSessionActive = false;
            _paymentInProgress = false;
            emit(
              PaymentFailure(
                'انتهت مهلة التحقق من حالة الدفع. يرجى التحقق يدوياً من حالة الدفع.',
              ),
            );

            // تنظيف
            _currentBookingId = null;
            _currentPaymentId = null;
            _currentChargeId = null;
          }
        } else {
          // للأخطاء الأخرى غير timeout، نتوقف بعد عدد محاولات أقل
          if (attempts >= 10) {
            timer.cancel();
            _paymentStatusTimer = null;
            _tapSessionActive = false;
            _paymentInProgress = false;
            emit(PaymentFailure('خطأ في التحقق من حالة الدفع: $e'));

            // تنظيف
            _currentBookingId = null;
            _currentPaymentId = null;
            _currentChargeId = null;
          }
        }
      }
    });

  }

  /// معالجة الدفع باستخدام Tap Checkout SDK
  /// نستخدم redirect URL من الباك إند لفتح صفحة الدفع
  /// المكتبة checkout_flutter تستخدم redirect URL للدفع
  Future<void> _processPaymentWithTapCheckout({
    required String redirectUrl,
    required String chargeId,
    required String paymentId,
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    required double amount,
  }) async {
    if (_tapSessionActive) {
      return;
    }

    try {
      _tapSessionActive = true;

      // طباعة معلومات الدفع للتشخيص

      // استخدام redirect URL لفتح صفحة الدفع
      // checkout_flutter يعمل مع redirect URLs من Tap Payments
      final bool opened = await _openTapPaymentPage(redirectUrl);

      if (!opened) {
        _tapSessionActive = false;
        emit(PaymentFailure('فشل فتح صفحة الدفع'));
      }
      // إذا تم فتح الصفحة بنجاح، سيتم التحقق من حالة الدفع عبر polling
    } catch (e) {
      _tapSessionActive = false;
      _paymentInProgress = false;

      String errorMessage = 'خطأ في تشغيل واجهة الدفع: $e';
      emit(PaymentFailure(errorMessage));
    }
  }

  /// فتح صفحة الدفع Tap Payments في المتصفح
  Future<bool> _openTapPaymentPage(String redirectUrl) async {
    try {

      String urlToLaunch = redirectUrl.trim();
      if (!urlToLaunch.startsWith('http://') &&
          !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }

      final Uri url = Uri.parse(urlToLaunch);

      if (!await canLaunchUrl(url)) {
        return false;
      }

      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// بدء التحقق الدوري من حالة الدفع لـ Event Request
  void _startEventRequestPaymentStatusPolling() {
    // إلغاء أي timer سابق
    _paymentStatusTimer?.cancel();

    int attempts = 0;
    const maxAttempts = 60; // 5 دقائق (60 * 8 ثوان)
    const pollingInterval = Duration(seconds: 8);

    _paymentStatusTimer = Timer.periodic(pollingInterval, (timer) async {
      attempts++;

      if (_currentEventRequestId == null || _currentPaymentId == null) {
        timer.cancel();
        return;
      }

      try {
        final confirmResult = await confirmPaymentUseCase(
          eventRequestId: _currentEventRequestId!,
          paymentId: _currentPaymentId!,
          chargeId: _currentChargeId,
        );

        if (confirmResult.success) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentSuccess(confirmResult));

          // تنظيف
          _currentEventRequestId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(
            PaymentFailure(
              'انتهت مهلة التحقق من حالة الدفع. يرجى التحقق يدوياً',
            ),
          );

          // تنظيف
          _currentEventRequestId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentFailure('خطأ في التحقق من حالة الدفع'));
        }
      }
    });
  }

  /// بدء التحقق الدوري من حالة الدفع لـ Trip Request
  void _startTripRequestPaymentStatusPolling() {
    // إلغاء أي timer سابق
    _paymentStatusTimer?.cancel();

    int attempts = 0;
    const maxAttempts = 60;
    const pollingInterval = Duration(seconds: 8);

    _paymentStatusTimer = Timer.periodic(pollingInterval, (timer) async {
      attempts++;

      if (_currentTripRequestId == null || _currentPaymentId == null) {
        timer.cancel();
        return;
      }

      try {
        final confirmResult = await confirmPaymentUseCase(
          tripRequestId: _currentTripRequestId!,
          paymentId: _currentPaymentId!,
          chargeId: _currentChargeId,
        );

        if (confirmResult.success) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentSuccess(confirmResult));

          // تنظيف
          _currentTripRequestId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        } else if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(
            PaymentFailure(
              'انتهت مهلة التحقق من حالة الدفع. يرجى التحقق يدوياً',
            ),
          );

          // تنظيف
          _currentTripRequestId = null;
          _currentPaymentId = null;
          _currentChargeId = null;
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          timer.cancel();
          _paymentStatusTimer = null;
          _tapSessionActive = false;
          _paymentInProgress = false;
          emit(PaymentFailure('خطأ في التحقق من حالة الدفع'));
        }
      }
    });
  }

  /// التحقق من حالة الدفع
  Future<void> checkPaymentStatus({
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    String? subscriptionPurchaseId,
    String? offerBookingId,
    required String paymentId,
    String? chargeId,
  }) async {
    try {
      final confirmResult = await confirmPaymentUseCase(
        bookingId: bookingId,
        eventRequestId: eventRequestId,
        tripRequestId: tripRequestId,
        subscriptionPurchaseId: subscriptionPurchaseId,
        offerBookingId: offerBookingId,
        paymentId: paymentId,
        chargeId: chargeId,
      );

      if (confirmResult.success) {
        emit(PaymentSuccess(confirmResult));
      } else {
        emit(PaymentFailure('لم يتم إتمام عملية الدفع بعد'));
      }
    } catch (e) {
      emit(PaymentFailure('خطأ في التحقق من حالة الدفع: $e'));
    }
  }

  @override
  Future<void> close() {
    // تنظيف timer عند إغلاق Cubit
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;
    return super.close();
  }
}
