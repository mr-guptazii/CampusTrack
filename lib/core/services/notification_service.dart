import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Wraps flutter_local_notifications (for scheduled reminders) and
/// firebase_messaging (for push notifications, e.g. backup/sync alerts).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _classChannelId = 'class_reminders';
  static const String _dailyChannelId = 'daily_reminder';
  static const String _warningChannelId = 'attendance_warning';

  Future<void> init() async {
    // flutter_local_notifications and dart:io's Platform have no web
    // implementation; local reminders and FCM tokens aren't available in
    // the browser, so skip setup there entirely.
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _classChannelId,
        'Class Reminders',
        description: 'Reminds you 10 minutes before a class starts',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _dailyChannelId,
        'Daily Attendance Reminder',
        description: 'Daily reminder to mark today\'s attendance',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _warningChannelId,
        'Attendance Warnings',
        description: 'Warns when a subject falls below target percentage',
        importance: Importance.high,
      ));
    }

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getFcmToken() => kIsWeb ? Future.value(null) : _fcm.getToken();

  /// Schedules a one-off reminder [minutesBefore] a class starts.
  Future<void> scheduleClassReminder({
    required int id,
    required String subjectName,
    required String room,
    required DateTime classStart,
    int minutesBefore = 10,
  }) async {
    if (kIsWeb) return;
    final scheduledTime = classStart.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _local.zonedSchedule(
      id,
      'Upcoming class: $subjectName',
      'Starts in $minutesBefore minutes${room.isNotEmpty ? ' • Room $room' : ''}',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _classChannelId,
          'Class Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedules the recurring 8 PM daily attendance reminder.
  Future<void> scheduleDailyReminder() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 20);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));

    await _local.zonedSchedule(
      9000,
      'Mark today\'s attendance',
      'Don\'t forget to log today\'s classes in CampusTrack.',
      tz.TZDateTime.from(target, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          'Daily Attendance Reminder',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllReminders() => kIsWeb ? Future.value() : _local.cancelAll();

  Future<void> showTargetWarning(String subjectName, double percentage) async {
    if (kIsWeb) return;
    await _local.show(
      subjectName.hashCode,
      'Low attendance: $subjectName',
      'You are at ${percentage.toStringAsFixed(1)}% — below your target.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _warningChannelId,
          'Attendance Warnings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
