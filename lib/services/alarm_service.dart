import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String meetUrl = 'https://meet.google.com/vtu-qgxk-zrv';
  final ValueNotifier<bool> isAlarmRingingNotifier = ValueNotifier<bool>(false);
  static Timer? _fiveMinRecurringTimer;

  bool _isMorningAlarmEnabled = true;
  bool _isEveningAlarmEnabled = true;

  bool get isMorningAlarmEnabled => _isMorningAlarmEnabled;
  bool get isEveningAlarmEnabled => _isEveningAlarmEnabled;

  Future<void> loadAlarmPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMorningAlarmEnabled = prefs.getBool('isMorningAlarmEnabled') ?? true;
      _isEveningAlarmEnabled = prefs.getBool('isEveningAlarmEnabled') ?? true;
    } catch (e) {
      debugPrint('[AlarmService] Preference load error: $e');
    }
  }

  Future<void> setMorningAlarmEnabled(bool enabled) async {
    _isMorningAlarmEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMorningAlarmEnabled', enabled);
    } catch (_) {}
    await scheduleExactDailyAlarms();
  }

  Future<void> setEveningAlarmEnabled(bool enabled) async {
    _isEveningAlarmEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isEveningAlarmEnabled', enabled);
    } catch (_) {}
    await scheduleExactDailyAlarms();
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}

    await loadAlarmPreferences();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    await scheduleExactDailyAlarms();
  }

  Future<void> triggerTestAlarmNow() async {
    const androidDetails = AndroidNotificationDetails(
      'yfc_fellowship_alarm_channel_v3',
      'YFC Fellowship Alarms v3',
      channelDescription: 'Alarms for Morning Prayer and Evening Bible Study',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('shofar_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_join_meet',
          'Join Live Session 🎥',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_dismiss',
          'Dismiss ❌',
          cancelNotification: true,
        ),
      ],
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      999,
      '🔔 Test Alarm - Sound Verification',
      'Testing Shofar Alarm sound playback!',
      details,
      payload: 'test_alarm',
    );
  }

  @pragma('vm:entry-point')
  static void _onNotificationResponse(NotificationResponse details) async {
    AlarmService().stopAlarmLoop();
    if (details.actionId == 'action_join_meet') {
      await launchGoogleMeet();
    }
  }

  static Future<void> launchGoogleMeet() async {
    final Uri uri = Uri.parse(meetUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<void> showHeadsUpNotification({
    int notificationId = 888,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'yfc_general_heads_up_channel',
      'YFC General Notifications',
      channelDescription: 'General notifications and chat messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload ?? 'chat',
    );
  }

  void stopAlarm() {
    stopAlarmLoop();
  }

  void stopAlarmLoop() {
    isAlarmRingingNotifier.value = false;
    _fiveMinRecurringTimer?.cancel();
    _notificationsPlugin.cancel(888);
    _notificationsPlugin.cancel(101);
    _notificationsPlugin.cancel(102);
    try {
      WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> scheduleExactDailyAlarms() async {
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {}

      final now = tz.TZDateTime.now(tz.local);

      const androidDetails = AndroidNotificationDetails(
        'yfc_fellowship_alarm_channel_v3',
        'YFC Fellowship Alarms v3',
        channelDescription: 'Alarms for Morning Prayer and Evening Bible Study',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('shofar_alarm'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_join_meet',
            'Join Live Session 🎥',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'action_dismiss',
            'Dismiss ❌',
            cancelNotification: true,
          ),
        ],
      );

      const details = NotificationDetails(android: androidDetails);

      if (_isMorningAlarmEnabled) {
        var morningTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 4, 55);
        if (morningTime.isBefore(now)) {
          morningTime = morningTime.add(const Duration(days: 1));
        }

        await _notificationsPlugin.zonedSchedule(
          101,
          '🌅 Morning Prayer in 5 Minutes!',
          'Prepare your heart. Fellowship begins at 5:00 AM IST.',
          morningTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _notificationsPlugin.cancel(101);
      }

      if (_isEveningAlarmEnabled) {
        var eveningTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 55);
        if (eveningTime.isBefore(now)) {
          eveningTime = eveningTime.add(const Duration(days: 1));
        }

        await _notificationsPlugin.zonedSchedule(
          102,
          '📖 Evening Bible Study in 5 Minutes!',
          'Join the study session starting at 9:00 PM IST.',
          eveningTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _notificationsPlugin.cancel(102);
      }

      debugPrint('[AlarmService] Exact daily alarms updated. Morning: $_isMorningAlarmEnabled, Evening: $_isEveningAlarmEnabled');
    } catch (e) {
      debugPrint('[AlarmService Error] scheduleExactDailyAlarms: $e');
    }
  }
}
