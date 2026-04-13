import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../firebase_options.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize and show local notification for background messages
  try {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    // Initialize Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(initSettings);

    // Create notification channel for Android if needed
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );
      await localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }

    // Show notification if message has notification payload
    final notification = message.notification;
    if (notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await localNotifications.show(
        message.hashCode,
        notification.title ?? 'Alert',
        notification.body ?? '',
        notificationDetails,
        payload: message.data.toString(),
      );

    }
  } catch (e) {
  }
}

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  String? _fcmToken;
  bool _initialized = false;

  /// Initialize Firebase
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _messaging = FirebaseMessaging.instance;

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions asynchronously
      _requestPermissions();

      // Get FCM token asynchronously
      _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      _initialized = true;
    } catch (e) {
      // Do not rethrow — allows app to run without push when Play Services fails (e.g. emulator)
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications!
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }

  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

    } else if (Platform.isAndroid) {
      // Android 13+ (API 33+) requires runtime permission for POST_NOTIFICATIONS
      // On Android 12 and below, this will return granted automatically
      try {
        final status = await Permission.notification.status;

        if (status.isDenied) {
          final result = await Permission.notification.request();

          if (result.isGranted) {
          } else if (result.isPermanentlyDenied) {
          } else {
          }
        } else if (status.isGranted) {
        } else if (status.isPermanentlyDenied) {
        } else if (status.isLimited) {
        }
      } catch (e) {
        // Continue anyway - some Android versions handle permissions differently
      }
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _messaging!.getToken();

      // Register token with backend
      await _registerTokenWithBackend(_fcmToken!);

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerTokenWithBackend(newToken);
      });

      return _fcmToken;
    } catch (e) {
      return null;
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      String? userId;
      try {
        final userDataStr = await SecureStorageService().getUserData();
        if (userDataStr != null) {
          final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
          userId = userData['id'] as String?;
        }
      } catch (e) {
        // Continue without userId
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      await DioClient.instance.post(
        '${ApiConstants.baseUrl}/notifications/register-device',
        data: {
          'userId': userId, // Can be null now
          'token': token,
          'platform': platform,
        },
      );

    } catch (e) {
    }
  }

  /// Re-register token if user is logged in (call this after login)
  Future<void> registerTokenIfUserLoggedIn() async {
    if (_fcmToken == null) {
      await _getFCMToken();
      return;
    }

    await _registerTokenWithBackend(_fcmToken!);
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

      // Handle notification here (show local notification, update UI, etc.)
      await _handleNotification(message);
    });

    // Background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state
    _messaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle notification
  Future<void> _handleNotification(RemoteMessage message) async {

    // Show local notification when app is in foreground
    final notification = message.notification;
    if (notification != null && _localNotifications != null) {
      final title = notification.title ?? 'Alert';
      final body = notification.body ?? '';

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        await _localNotifications!.show(
          message.hashCode, // Use message hash as notification ID
          title,
          body,
          notificationDetails,
          payload: jsonEncode(message.data),
        );
      } catch (e) {
      }
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification type
    // Example: if type is 'BOOKING_CONFIRMED', navigate to booking details
    // This should be handled by your navigation service
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Unregister device token
  Future<void> unregisterDevice() async {
    if (_fcmToken == null) return;

    try {
      await DioClient.instance.delete(
        '${ApiConstants.baseUrl}/notifications/unregister-device',
        data: {'token': _fcmToken},
      );
    } catch (e) {
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging!.subscribeToTopic(topic);
    } catch (e) {
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging!.unsubscribeFromTopic(topic);
    } catch (e) {
    }
  }
}
