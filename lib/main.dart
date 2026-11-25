// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:man_of_cave/totalpay_service.dart';

import 'Screens/chats/chat_room_screen.dart';
import 'Screens/my_booking_screen.dart';
import 'Screens/splash_screen.dart';
import 'constants/app_sizes.dart';
import 'constants/app_strings.dart';
import 'controlers/auth_controller.dart';
import 'controlers/banner_controller.dart';
import 'controlers/booking_controller.dart';
import 'controlers/branches_controller.dart';
import 'controlers/cart_controller.dart';
import 'controlers/category_controller.dart';
import 'controlers/chat_controller.dart';
import 'controlers/customer_controller.dart';
import 'controlers/feedback_controller.dart';
import 'controlers/loyalty_points_controller.dart';
import 'controlers/notification_controller.dart';
import 'controlers/order_controller.dart';
import 'controlers/product_controller.dart';
import 'controlers/promo_code_controller.dart';
import 'controlers/referral_controller.dart';
import 'controlers/service_controller.dart';
import 'controlers/staff_controller.dart';
import 'controlers/theme_controller.dart';
import 'controlers/totalpay_controller.dart';
import 'controlers/user_controller.dart';
import 'controlers/wallet_controller.dart';
import 'firebase_options.dart';

// Global notification local plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 Handling background message: ${message.messageId}");
  await _showLocalNotification(message);
}

// Show local notification
Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert_sound'),
    enableVibration: true,
    color: Color(0xFFC5A059),
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
  DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'alert_sound.mp3',
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  String title = message.notification?.title ?? AppStrings.appName;
  String body = message.notification?.body ?? 'You have a new notification';

  if (title == AppStrings.appName && message.data.containsKey('title')) {
    title = message.data['title'] ?? title;
  }
  if (body == 'You have a new notification' && message.data.containsKey('body')) {
    body = message.data['body'] ?? body;
  }

  await flutterLocalNotificationsPlugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    payload: message.data['type'] ?? 'notification',
    notificationDetails: platformChannelSpecifics,
  );
}

// Initialize local notifications
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('🔔 Notification tapped: ${response.payload}');
      if (response.payload != null) {
        _handleNotificationPayload(response.payload!);
      }
    },
  );
}

// Handle notification payload
void _handleNotificationPayload(String payload) {
  // Parse the payload and navigate
  print('🔔 Handling notification payload: $payload');
  // You can add more sophisticated navigation logic here
}

// Create notification channel with custom sound
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert_sound'),
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFFC5A059),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  print('✅ Notification channel created with custom sound: alert_sound.mp3');
}

// Show in-app notification (snackbar)
void _showInAppNotification(RemoteMessage message) {
  final title = message.notification?.title ??
      message.data['title'] ??
      'Notification';
  final body = message.notification?.body ??
      message.data['body'] ??
      'You have a new notification';
  final type = message.data['type'] ?? 'system';

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFC5A059).withOpacity(0.95),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: _getNotificationIcon(type),
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // Close snackbar
          _handleNavigation(message.data);
        },
        child: const Text(
          'VIEW',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  });
}

// Get notification icon based on type
Icon _getNotificationIcon(String type) {
  IconData iconData;
  switch (type.toLowerCase()) {
    case 'booking':
      iconData = Icons.calendar_today;
      break;
    case 'order':
      iconData = Icons.shopping_bag;
      break;
    case 'chat':
      iconData = Icons.chat_bubble_outline;
      break;
    case 'loyalty':
      iconData = Icons.stars;
      break;
    case 'offer':
      iconData = Icons.local_offer;
      break;
    default:
      iconData = Icons.notifications;
  }
  return Icon(iconData, color: Colors.white, size: 20);
}

// Handle navigation from notification
void _handleNavigation(Map<String, dynamic> data) {
  final type = data['type'];
  final targetId = data['targetId'] ?? data['bookingId'] ?? data['orderId'] ?? data['roomId'];

  print('🔔 Navigating from notification - Type: $type, ID: $targetId');

  Future.delayed(const Duration(milliseconds: 500), () {
    switch (type?.toLowerCase()) {
      case 'booking':
        if (targetId != null && targetId.isNotEmpty) {
          Get.toNamed('/booking-detail', arguments: {'bookingId': targetId});
        } else {
          Get.toNamed('/my-bookings');
        }
        break;
      case 'order':
        if (targetId != null && targetId.isNotEmpty) {
          Get.toNamed('/order-detail', arguments: {'orderId': targetId});
        } else {
          Get.toNamed('/my-orders');
        }
        break;
      case 'chat':
        if (targetId != null && targetId.isNotEmpty) {
          Get.toNamed('/chat-room', arguments: {'roomId': targetId});
        }
        break;
      case 'loyalty':
        Get.toNamed('/profile');
        break;
      case 'offer':
        Get.toNamed('/offers');
        break;
      default:
        Get.toNamed('/home');
    }
  });
}

Future<void> _setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  try {
    await messaging
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        )
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    print('⚠️ FCM permission skipped: $e');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📱 Foreground message received');
    _showLocalNotification(message);
    _showInAppNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📱 App opened from notification');
    _handleNavigation(message.data);
  });

  try {
    final initialMessage = await messaging
        .getInitialMessage()
        .timeout(const Duration(seconds: 5));
    if (initialMessage != null) {
      print('📱 App opened from terminated state');
      _handleNavigation(initialMessage.data);
    }
  } catch (e) {
    print('⚠️ FCM initial message skipped: $e');
  }

  try {
    final token = await messaging
        .getToken()
        .timeout(const Duration(seconds: 10));
    print('📱 FCM Token: $token');
  } catch (e) {
    print('⚠️ FCM token skipped: $e');
  }

  try {
    await messaging
        .subscribeToTopic('all_users')
        .timeout(const Duration(seconds: 8));
    await messaging
        .subscribeToTopic('offers')
        .timeout(const Duration(seconds: 8));
    print('📱 Subscribed to topics');
  } catch (e) {
    print('⚠️ FCM topic subscribe skipped: $e');
  }
}

void _registerControllers() {
  // Eager: only what splash/auth need immediately.
  Get.put(ThemeController(), permanent: true);
  Get.put(WalletController(), permanent: true);
  Get.put(LoyaltyController(), permanent: true);
  Get.put(AuthController(), permanent: true);

  // Lazy: created on first Get.find — avoids N parallel Firestore loads at cold start.
  Get.lazyPut(() => UserController(), fenix: true);
  Get.lazyPut(() => TotalPayController(), fenix: true);
  Get.lazyPut(() => CustomerController(), fenix: true);
  Get.lazyPut(() => NotificationController(), fenix: true);
  Get.lazyPut(() => PromoCodeController(), fenix: true);
  Get.lazyPut(() => BranchController(), fenix: true);
  Get.lazyPut(() => CategoryController(), fenix: true);
  Get.lazyPut(() => ServiceController(), fenix: true);
  Get.lazyPut(() => ProductController(), fenix: true);
  Get.lazyPut(() => BannerController(), fenix: true);
  Get.lazyPut(() => StaffController(), fenix: true);
  Get.lazyPut(() => BookingController(), fenix: true);
  Get.lazyPut(() => ChatController(), fenix: true);
  Get.lazyPut(() => CartController(), fenix: true);
  Get.lazyPut(() => OrderController(), fenix: true);
  Get.lazyPut(() => FeedbackController(), fenix: true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await GetStorage.init();
    print('✅ GetStorage initialized');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Must be registered before runApp; actual FCM I/O runs after first frame.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _registerControllers();
    print('✅ Controllers registered (lazy catalog)');

    runApp(const MyApp());

    // Heavy native/plugin work after first frames so UI stays responsive.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let splash/login paint before spinning up payment + FCM engines.
      await Future.delayed(const Duration(seconds: 2));
      try {
        await TotalPayService.init();
      } catch (e) {
        print('⚠️ TotalPay init skipped: $e');
      }
      try {
        await _createNotificationChannel();
        await _initializeLocalNotifications();
        print('✅ Local notifications initialized');
      } catch (e) {
        print('⚠️ Local notifications skipped: $e');
      }
      // FCM can spawn a second FlutterEngine — keep it off the cold-start path.
      await Future.delayed(const Duration(seconds: 1));
      _setupFirebaseMessaging();
    });
  } catch (e, stack) {
    print('❌ Error during initialization: $e');
    print('Stack trace: $stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        AppSizes.init(context);
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF6F5F3),
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF695A2D),
              secondary: const Color(0xFF5A4A20),
              surface: Colors.white,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1C1917),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: false,
              backgroundColor: Color(0xFF695A2D),
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF695A2D), width: 1.4),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}