class ApiConstants {
  // Base URL - Choose the appropriate one based on your setup:
  // For production server:
  static const String baseUrl = 'http://192.168.1.3:3000/api/v1';

  // For Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // For iOS simulator (if needed):
  // static const String baseUrl = 'http://localhost:3000/api/v1';

  // For physical device on same network (replace with your computer's IP):
  // static const String baseUrl = 'https://kinetic-app-sa.org/api/v1';

  static void printEndpoints() {}

  // Authentication Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String sendOtpEndpoint = '/auth/otp/send';
  static const String verifyOtpEndpoint = '/auth/otp/verify';
  static const String registerSendOtpEndpoint = '/auth/register/otp/send';
  static const String registerVerifyOtpEndpoint = '/auth/register/otp/verify';
  static const String completeRegistrationEndpoint = '/auth/register/complete';
  static const String profileEndpoint = '/auth/me';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String emailConfigEndpoint = '/auth/email-config';
  static const String updateLanguageEndpoint = '/auth/language';
  static const String forgotPasswordSendOtpEndpoint =
      '/auth/forgot-password/otp/send';
  static const String forgotPasswordResetEndpoint = '/auth/forgot-password/reset';

  // User Profile Endpoints
  static const String updateProfileEndpoint = '/users/profile';
  static const String deleteAccountEndpoint = '/users/profile';

  // Wallet Endpoints
  static const String walletBalanceEndpoint = '/wallets/me';
  static const String walletTransactionsEndpoint = '/wallets/me/transactions';
  static const String walletRechargeEndpoint = '/wallets/recharge';

  // Loyalty Endpoints
  static const String loyaltyMeEndpoint = '/loyalty/me';
  static const String loyaltyRedeemTicketEndpoint = '/loyalty/redeem-ticket';

  // Home Endpoints
  static const String homeEndpoint = '/home';
  static const String branchDetailsEndpoint = '/content/branches';
  static const String branchesEndpoint = '/content/branches';

  // Subscriptions
  static String branchSubscriptionPlans(String branchId) =>
      '/branches/$branchId/subscription-plans';
  static const String subscriptionPurchasesEndpoint = '/subscription-purchases';
  static const String subscriptionQuoteEndpoint =
      '/subscription-purchases/quote';
  static const String mySubscriptionsEndpoint = '/subscription-purchases/me';
  static String subscriptionPurchaseDetails(String id) =>
      '/subscription-purchases/$id';
  static String subscriptionPurchaseUsageLogs(String id) =>
      '/subscription-purchases/$id/usage-logs';

  // Offer products & bookings (catalog offers, not booking discounts)
  static String branchOfferProducts(String branchId) =>
      '/branches/$branchId/offer-products';
  static const String offerBookingsEndpoint = '/offer-bookings';
  static const String offerQuoteEndpoint = '/offer-bookings/quote';
  static String offerBookingDetails(String id) => '/offer-bookings/$id';
  static String offerBookingTickets(String id) => '/offer-bookings/$id/tickets';

  // Coupons (standalone preview)
  static const String couponPreviewEndpoint = '/coupons/preview';

  static String paymentDetails(String paymentId) => '/payments/$paymentId';

  // Event Requests Endpoints
  static const String eventsConfigEndpoint = '/events/config';
  static const String eventsRequestsEndpoint = '/events/requests';
  static const String eventsRequestsCreateEndpoint = '/events/requests';
  static String eventsRequestDetailEndpoint(String id) =>
      '/events/requests/$id';

  /// School trips public config (add-ons, time slots for date).
  static const String tripsConfigEndpoint = '/trips/config';

  // Notifications Endpoints
  static const String notificationsEndpoint = '/notifications';
  static const String notificationsUnreadCountEndpoint =
      '/notifications/unread-count';
  static const String registerDeviceEndpoint = '/notifications/register-device';
  static const String unregisterDeviceEndpoint =
      '/notifications/unregister-device';

  // Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String applicationJson = 'application/json';
  static const String bearerPrefix = 'Bearer ';

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Tap Payments Configuration
  // Test Public Key - Replace with production key when ready
  static const String tapPublicKey = 'pk_test_uwXLKNceB0YZfmVD8xlITM2z';

  // Moyasar publishable key used by Flutter checkout UI.
  static const String moyasarPublishableKey =
      'pk_test_YQE7QedoWj3Mw7xyfh44HaN1WWwRdioQoeer6foL';

  // Apple Pay configuration for Moyasar checkout (iOS only).
  static const String moyasarApplePayMerchantId = String.fromEnvironment(
    'MOYASAR_APPLE_PAY_MERCHANT_ID',
    defaultValue: 'merchant.com.kantic.app',
  );
  static const String moyasarApplePayLabel = String.fromEnvironment(
    'MOYASAR_APPLE_PAY_LABEL',
    defaultValue: 'Kantic',
  );
}
