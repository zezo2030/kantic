# نظام الإشعارات - Firebase + Local Storage

## 📋 نظرة عامة
نظام متكامل لإدارة الإشعارات باستخدام Firebase Cloud Messaging مع التخزين المحلي باستخدام Hive.

## ✨ المميزات
- ✅ استقبال إشعارات Firebase في الخلفية والمقدمة
- ✅ حفظ أنواع معينة فقط من الإشعارات (حجوزات، رحلات، عروض)
- ✅ عرض الإشعارات في صفحة مخصصة
- ✅ تمييز الإشعارات المقروءة وغير المقروءة
- ✅ عداد للإشعارات غير المقروءة
- ✅ السحب للحذف
- ✅ التنقل التلقائي حسب نوع الإشعار

## 📦 المتطلبات

أضف هذه الحزم في `pubspec.yaml`:

```yaml
dependencies:
  # Firebase
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  
  # Local Notifications
  flutter_local_notifications: ^16.3.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # State Management
  flutter_bloc: ^8.1.3
  
dev_dependencies:
  # Code Generation
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

## 🔧 الإعداد

### 1. تهيئة Firebase

في ملف `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/notifications/data/models/notification_model.dart';
import 'features/notifications/data/datasources/notifications_local_datasource.dart';
import 'features/notifications/services/firebase_messaging_service.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters
  Hive.registerAdapter(NotificationModelAdapter());
  
  // Initialize services
  final localDataSource = NotificationsLocalDataSource();
  await localDataSource.init();
  
  final messagingService = FirebaseMessagingService(localDataSource);
  await messagingService.initialize();
  
  runApp(MyApp(
    localDataSource: localDataSource,
    messagingService: messagingService,
  ));
}

class MyApp extends StatelessWidget {
  final NotificationsLocalDataSource localDataSource;
  final FirebaseMessagingService messagingService;
  
  const MyApp({
    required this.localDataSource,
    required this.messagingService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NotificationsCubit(localDataSource),
        ),
        // ... other providers
      ],
      child: MaterialApp(
        // ... app configuration
      ),
    );
  }
}
```

### 2. توليد Hive Adapters

قم بتشغيل الأمر التالي:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. إعداد Firebase في المشروع

1. أضف ملف `google-services.json` (Android) في `android/app/`
2. أضف ملف `GoogleService-Info.plist` (iOS) في `ios/Runner/`
3. قم بتفعيل Firebase Cloud Messaging في Firebase Console

## 📱 الاستخدام

### إرسال إشعار من Firebase Console

عند إرسال إشعار، أضف البيانات التالية في قسم "Additional options":

```json
{
  "type": "booking",  // أو "trip" أو "offer"
  "id": "123",
  "bookingId": "booking_123"  // حسب النوع
}
```

### أنواع الإشعارات المدعومة

| النوع | الوصف | البيانات المطلوبة |
|------|------|------------------|
| `booking` | إشعارات الحجوزات | `bookingId` |
| `trip` | إشعارات الرحلات | `tripId` |
| `offer` | إشعارات العروض | - |

**ملاحظة:** فقط الإشعارات من هذه الأنواع سيتم حفظها محلياً.

### الوصول إلى صفحة الإشعارات

```dart
Navigator.pushNamed(context, '/notifications');
```

### الحصول على عدد الإشعارات غير المقروءة

```dart
final cubit = context.read<NotificationsCubit>();
final unreadCount = await cubit.getUnreadCount();
```

### تحديث الإشعارات عند استقبال إشعار جديد

```dart
context.read<NotificationsCubit>().refresh();
```

## 🎯 التخصيص

### تغيير الأنواع المسموح بحفظها

في ملف `notifications_local_datasource.dart`:

```dart
bool shouldSaveNotification(String type) {
  const allowedTypes = ['booking', 'trip', 'offer', 'payment']; // أضف أنواع جديدة
  return allowedTypes.contains(type.toLowerCase());
}
```

### تخصيص التنقل حسب نوع الإشعار

في ملف `notifications_page.dart`، عدّل دالة `_handleNotificationTap`:

```dart
void _handleNotificationTap(BuildContext context, NotificationModel notification) {
  switch (notification.type) {
    case 'booking':
      // التنقل إلى صفحة تفاصيل الحجز
      break;
    case 'trip':
      // التنقل إلى صفحة تفاصيل الرحلة
      break;
    // ... أضف حالات جديدة
  }
}
```

## 🔔 إضافة Badge للإشعارات غير المقروءة

في الهيدر أو أي مكان آخر:

```dart
BlocBuilder<NotificationsCubit, NotificationsState>(
  builder: (context, state) {
    final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;
    
    return Badge(
      label: Text('$unreadCount'),
      isLabelVisible: unreadCount > 0,
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () => Navigator.pushNamed(context, '/notifications'),
      ),
    );
  },
)
```

## 🧪 اختبار الإشعارات

### إرسال إشعار تجريبي من Firebase Console:

1. افتح Firebase Console
2. اذهب إلى Cloud Messaging
3. اضغط "Send your first message"
4. املأ العنوان والنص
5. في "Additional options" > "Custom data"، أضف:
   - Key: `type`, Value: `booking`
   - Key: `bookingId`, Value: `123`
6. أرسل الإشعار

## 📝 ملاحظات مهمة

1. **الإشعارات في الخلفية**: تأكد من أن التطبيق لديه صلاحيات الإشعارات
2. **iOS**: قد تحتاج إلى إعدادات إضافية في Xcode
3. **التخزين المحلي**: البيانات محفوظة حتى بعد إغلاق التطبيق
4. **الأداء**: يتم حفظ الإشعارات المحددة فقط لتوفير المساحة

## 🐛 استكشاف الأخطاء

### الإشعارات لا تظهر؟
- تحقق من صلاحيات الإشعارات
- تأكد من تهيئة Firebase بشكل صحيح
- راجع console logs

### الإشعارات لا تُحفظ؟
- تحقق من نوع الإشعار (type)
- تأكد من تهيئة Hive
- راجع دالة `shouldSaveNotification`

## 📚 المراجع

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Hive Documentation](https://docs.hivedb.dev/)
