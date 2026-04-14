import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_links/app_links.dart';
import 'core/constants/api_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'features/auth/di/auth_injection.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/payments/di/payments_injection.dart' as payments_di;
import 'core/routes/app_route_generator.dart';
import 'features/notifications/services/firebase_messaging_service.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';

// Global navigator key for deep links
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await firebaseBackgroundMessageHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (non-fatal: app continues without push if this fails)
  try {
    await FirebaseService.instance.initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Do not rethrow — avoids crash when Play Services unavailable (e.g. emulator without Google Play)
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Notification Services
  final messagingService = FirebaseMessagingService();
  await messagingService.initialize();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize dependency injection
  await init();
  payments_di.initPayments(); // Initialize payments feature

  // Print API endpoints
  ApiConstants.printEndpoints();

  // Initialize deep links
  _initDeepLinks();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

/// إعداد معالج Deep Links للدفع
void _initDeepLinks() {
  final appLinks = AppLinks();

  // استماع للـ deep links عند فتح التطبيق
  appLinks
      .getInitialLink()
      .then((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        } else {}
      })
      .catchError((e) {});

  // استماع للـ deep links أثناء تشغيل التطبيق
  appLinks.uriLinkStream.listen(
    (Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    },
    onError: (e) {},
    cancelOnError: false,
  );
}

/// معالجة Deep Link
void _handleDeepLink(Uri uri) {
  try {
    // التحقق من أن الـ deep link هو للدفع
    // نتحقق من scheme
    final isValidScheme = uri.scheme == 'loopmsq' || uri.scheme == 'intent';

    if (isValidScheme) {
      // معالجة intent:// scheme (Android)
      if (uri.scheme == 'intent') {
        // استخراج paymentId من query parameters
        final paymentId =
            uri.queryParameters['paymentId'] ?? uri.queryParameters['id'];
        if (paymentId != null && paymentId.isNotEmpty) {
          _navigateToPaymentSuccess(paymentId);
          return;
        }
      }

      // معالجة loopmsq:// scheme
      if (uri.scheme == 'loopmsq') {
        final path = uri.path;
        final host = uri.host;

        // Handle payment success
        if (host == 'payment' &&
            (path == '/success' || path.contains('success'))) {
          final paymentId =
              uri.queryParameters['paymentId'] ?? uri.queryParameters['id'];

          if (paymentId != null && paymentId.isNotEmpty) {
            _navigateToPaymentSuccess(paymentId);
          } else {}
        } else {}
      } else {}
    } else {}
  } catch (e) {}
}

/// الانتقال إلى صفحة نجاح الدفع
void _navigateToPaymentSuccess(String paymentId) {
  // الانتقال إلى صفحة نجاح الدفع
  // نستخدم navigatorKey للوصول إلى Navigator من خارج context
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.paymentSuccess,
        arguments: {'paymentId': paymentId},
      );
    } else {
      // إعادة المحاولة بعد تأخير قصير
      Future.delayed(const Duration(milliseconds: 500), () {
        final retryContext = navigatorKey.currentContext;
        if (retryContext != null) {
          Navigator.of(retryContext).pushNamed(
            AppRoutes.paymentSuccess,
            arguments: {'paymentId': paymentId},
          );
        } else {}
      });
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthCubit>()..checkAuthStatus()),
        BlocProvider(
          create: (context) => sl<NotificationsCubit>()..loadNotifications(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // إضافة navigatorKey للوصول من deep links
        title: 'User App',
        debugShowCheckedModeBanner: false,

        // Localization
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        // Theme
        theme: AppTheme.lightTheme,

        // Dark Theme
        darkTheme: AppTheme.darkTheme,

        // Force light mode always
        themeMode: ThemeMode.light,

        // Routes
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRouteGenerator.generateRoute,
      ),
    );
  }
}
