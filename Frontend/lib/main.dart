import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'navigation/app_navigation.dart';
import 'services/chat_service.dart';
import 'viewmodel/payment_view_model.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pick file via --dart-define (ENV_FILE) or fall back to dev/prod by mode
  const envFile = String.fromEnvironment(
    'ENV_FILE',
    defaultValue: '.env.dev',
  );
  await dotenv.load(fileName: envFile);

  await Firebase.initializeApp();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await setupInteractedMessage();
  // Initialize WebView for PayPal integration
  WebViewPlatform.instance;
  runApp(const ShareCycleApp());
}

class ShareCycleApp extends StatelessWidget {
  const ShareCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        Provider(create: (_) => ChatService()),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Call this from your main() function
Future<void> setupInteractedMessage() async {
  final prefs = await SharedPreferences.getInstance();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 1. Request Permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  String fcmToken = await messaging.getToken() ?? "";
  print("====================================");
  print("YOUR FCM TOKEN: $fcmToken");
  print("====================================");
  await prefs.setString("fcm_token", fcmToken);

  // =======================================================================
  // ADD THIS BLOCK: Handle FOREGROUND Messages
  // =======================================================================
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print(message.data);

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    final roomId = message.data['chatRoomId'] as String ?? '';
    final owner = prefs.getString("owner_id") ?? '';
    final renter = prefs.getString("renter_id") ?? '';

    print("roomId: " + roomId + " ownerId: "+ owner + " renterId: "+renter);
    // This is the key: if we get a notification, show it

    if(owner.isNotEmpty && renter.isNotEmpty && roomId.contains(owner) && roomId.contains(renter)) {
      return;
    };

    if (notification != null && android != null) {
      // This command creates the system notification
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id, // Use the channel ID you created
            channel.name, // Use the channel name
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher', // Use your icon name again
          ),
        ),
      );
    }
  });

  // Handle taps from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('User tapped notification from background:');
    // Add navigation logic here if needed
  });

  // Handle taps from terminated
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('App launched from terminated state by notification:');
    // Add navigation logic here if needed
  }
}
