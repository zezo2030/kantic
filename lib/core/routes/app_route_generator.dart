import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../features/auth/presentation/screens/complete_registration_screen.dart';
import '../../features/auth/presentation/screens/kinetic_login_screen.dart';
import '../../features/auth/presentation/screens/kinetic_otp_login_screen.dart';
import '../../features/auth/presentation/screens/kinetic_otp_verify_screen.dart';
import '../../features/auth/presentation/screens/otp_login_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/home/presentation/pages/branch_details_page.dart';
import '../../features/main/presentation/screens/main_screen.dart';
import '../../features/trips/domain/entities/school_trip_request_entity.dart';
import '../../features/trips/presentation/pages/trip_request_details_page.dart';
import '../../features/trips/presentation/pages/trip_request_wizard_page.dart';
import '../../features/trips/presentation/pages/trip_requests_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/payments/presentation/pages/payment_success_page.dart';
import '../../features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_details_page.dart';
import '../../features/offer_products/presentation/pages/my_offer_bookings_page.dart';
import '../../features/offer_products/presentation/pages/offer_booking_details_page.dart';
import '../../features/home/presentation/pages/offers_landing_page.dart';
import '../../features/loyalty/presentation/screens/loyalty_screen.dart';
import '../../features/booking/presentation/pages/my_hall_tickets_page.dart';

class AppRoutes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const otpLogin = '/otp-login';
  static const otpLoginKinetic = '/otp-login-kinetic';
  static const register = '/register';
  static const otpVerify = '/otp-verify';
  static const otpVerifyKinetic = '/otp-verify-kinetic';
  static const completeRegistration = '/complete-registration';
  static const profile = '/profile';
  static const main = '/main';
  static const branchDetails = '/branch-details';
  static const schoolTrips = '/school-trips';
  static const schoolTripsCreate = '/school-trips/create';
  static const schoolTripsDetails = '/school-trips/details';
  static const notifications = '/notifications';
  static const paymentSuccess = '/payment-success';
  static const offers = '/offers';
  static const mySubscriptions = '/my-subscriptions';
  static const subscriptionDetails = '/subscription-details';
  static const myOfferBookings = '/my-offer-bookings';
  static const offerBookingDetails = '/offer-booking-details';
  static const loyalty = '/loyalty';
  static const myHallTickets = '/my-hall-tickets';
}

class AppRouteGenerator {
  const AppRouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (context) => const WelcomeScreen());
      case AppRoutes.login:
        return _buildSoftFadeRoute(
          settings: settings,
          page: const KineticLoginScreen(),
        );
      case AppRoutes.otpLogin:
        return MaterialPageRoute(builder: (context) => const OtpLoginScreen());
      case AppRoutes.otpLoginKinetic:
        return _buildSoftFadeRoute(
          settings: settings,
          page: const KineticOtpLoginScreen(),
        );
      case AppRoutes.register:
        return _buildSoftFadeRoute(
          settings: settings,
          page: const RegisterScreen(),
        );
      case AppRoutes.otpVerify:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildSoftFadeRoute(
          settings: settings,
          page: OtpVerifyScreen(
            phone: args?['phone'] ?? '',
            isRegistration: args?['isRegistration'] ?? false,
          ),
        );
      case AppRoutes.otpVerifyKinetic:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildSoftFadeRoute(
          settings: settings,
          page: KineticOtpVerifyScreen(
            phone: args?['phone'] ?? '',
            isRegistration: args?['isRegistration'] ?? false,
          ),
        );
      case AppRoutes.completeRegistration:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildSoftFadeRoute(
          settings: settings,
          page: const CompleteRegistrationScreen(),
          arguments: args,
        );
      case AppRoutes.profile:
        return _buildProtectedRoute(
          settings: settings,
          page: const ProfileScreen(),
        );
      case AppRoutes.main:
        return MaterialPageRoute(builder: (context) => const MainScreen());
      case AppRoutes.branchDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) =>
              BranchDetailsPage(branchId: args?['branchId'] ?? ''),
        );
      case AppRoutes.schoolTrips:
        return MaterialPageRoute(
          builder: (context) => const TripRequestsPage(),
        );
      case AppRoutes.schoolTripsCreate:
        return MaterialPageRoute(
          builder: (context) => const TripRequestWizardPage(),
        );
      case AppRoutes.schoolTripsDetails:
        final args = settings.arguments;
        SchoolTripRequestEntity? request;
        if (args is SchoolTripRequestEntity) {
          request = args;
        } else if (args is Map<String, dynamic>) {
          request = args['request'] as SchoolTripRequestEntity?;
        }
        final requestId =
            request?.id ??
            (args is Map<String, dynamic>
                ? args['requestId'] as String?
                : null);
        return MaterialPageRoute(
          builder: (context) => TripRequestDetailsPage(
            requestId: requestId ?? request?.id ?? '',
            initialRequest: request,
          ),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (context) => const NotificationsPage(),
        );
      case AppRoutes.paymentSuccess:
        final args = settings.arguments as Map<String, dynamic>?;
        final paymentId = args?['paymentId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (context) => PaymentSuccessPage(paymentId: paymentId),
        );
      case AppRoutes.offers:
        return MaterialPageRoute(
          builder: (context) => const OffersLandingPage(),
        );
      case AppRoutes.mySubscriptions:
        return _buildProtectedRoute(
          settings: settings,
          page: const MySubscriptionsPage(),
        );
      case AppRoutes.myOfferBookings:
        return _buildProtectedRoute(
          settings: settings,
          page: const MyOfferBookingsPage(),
        );
      case AppRoutes.myHallTickets:
        return _buildProtectedRoute(
          settings: settings,
          page: const MyHallTicketsPage(),
        );
      case AppRoutes.subscriptionDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final purchaseId = args?['purchaseId'] as String? ?? '';
        return _buildProtectedRoute(
          settings: settings,
          page: SubscriptionDetailsPage(purchaseId: purchaseId),
        );
      case AppRoutes.offerBookingDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final bookingId = args?['bookingId'] as String? ?? '';
        return _buildProtectedRoute(
          settings: settings,
          page: OfferBookingDetailsPage(bookingId: bookingId),
        );
      case AppRoutes.loyalty:
        return _buildProtectedRoute(
          settings: settings,
          page: const LoyaltyScreen(),
        );
      default:
        return MaterialPageRoute(builder: (context) => const WelcomeScreen());
    }
  }
}

PageRoute<dynamic> _buildSoftFadeRoute({
  required RouteSettings settings,
  Map<String, dynamic>? arguments,
  required Widget page,
}) {
  final routeSettings = RouteSettings(
    name: settings.name,
    arguments: arguments ?? settings.arguments,
  );

  return PageRouteBuilder(
    settings: routeSettings,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.05),
        end: Offset.zero,
      ).animate(curvedAnimation);
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

PageRoute<dynamic> _buildProtectedRoute({
  required RouteSettings settings,
  required Widget page,
}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) {
      // Check authentication state
      final authState = context.read<AuthCubit>().state;
      if (authState is Guest) {
        // Redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('login_required'.tr()),
              backgroundColor: Colors.orange,
            ),
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.05),
        end: Offset.zero,
      ).animate(curvedAnimation);
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}
