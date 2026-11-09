import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService.showNotificationFromRemote(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Function(String? payload)? onNotificationTap;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'yfc_high_importance_channel',
    'YFC Fellowship Alerts',
    description: 'Real-time banners for fellowship chat, quizzes, and prayer requests',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize({Function(String? payload)? onTap}) async {
    onNotificationTap = onTap;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;

    // Request Android 13+ runtime permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe all devices to fellowship topic for group broadcast alerts
    await messaging.subscribeToTopic('fellowship_announcements');
    await messaging.subscribeToTopic('fellowship_chat');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Display banner if app is open in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotificationFromRemote(message);
    });

    // Handle tapping notification when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = message.data['type'] ?? 'chat';
      onNotificationTap?.call(payload);
    });
  }

  static void showNotification({
    required String title,
    required String body,
    String payload = 'chat',
  }) {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static void showNotificationFromRemote(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'YFC Fellowship';
    final body = notification?.body ?? message.data['body'] ?? 'New fellowship update';
    final payload = message.data['type'] ?? 'chat';

    showNotification(title: title, body: body, payload: payload);
  }
}
