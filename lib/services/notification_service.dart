import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/reminder.dart';

typedef OnNotificationTap = void Function(String? reminderId);

// Manages local notification scheduling for bill/EMI reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  OnNotificationTap? onNotificationTap;

  static const int _notificationHour = 9;
  static const int _notificationMinute = 0;

  // Initialize notification service.
  Future<void> initialize() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_getLocalTimezone()));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  // Handle notification response tap.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }

  // Retrieve current device timezone identifier.
  String _getLocalTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      for (final location in tz.timeZoneDatabase.locations.values) {
        final now = tz.TZDateTime.now(location);
        if (now.timeZoneOffset == offset) {
          return location.name;
        }
      }
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();
      if (hours == 5 && minutes == 30) return 'Asia/Kolkata';
      return 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  // Request user permissions for notifications.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    bool granted = true;

    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.request();
      if (!notifStatus.isGranted) {
        granted = false;
      }
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      if (!alarmStatus.isGranted) {
        if (kDebugMode) {
          print('Exact alarm permission not granted.');
        }
      }
    }
    return granted;
  }

  // Reschedule notifications for all unpaid reminders.
  Future<void> scheduleAllReminders(List<Reminder> reminders) async {
    if (kIsWeb) return;
    await _plugin.cancelAll();

    for (final reminder in reminders) {
      if (!reminder.isPaidThisCycle) {
        await _scheduleReminderNotifications(reminder);
      }
    }
  }

  // Schedule notifications for a single reminder over its active window.
  Future<void> _scheduleReminderNotifications(Reminder reminder) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);

    for (int monthOffset = 0; monthOffset <= 1; monthOffset++) {
      int year = now.year;
      int month = now.month + monthOffset;
      if (month > 12) {
        month -= 12;
        year += 1;
      }

      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      final effectiveDayEnd = reminder.dayEnd.clamp(1, lastDayOfMonth);
      final effectiveDayStart = reminder.dayStart.clamp(1, lastDayOfMonth);

      for (int day = effectiveDayStart; day <= effectiveDayEnd; day++) {
        final scheduledDate = tz.TZDateTime(
          tz.local,
          year,
          month,
          day,
          _notificationHour,
          _notificationMinute,
        );

        if (scheduledDate.isAfter(now)) {
          final notificationId = _generateNotificationId(
            reminder.id,
            year,
            month,
            day,
          );

          await _plugin.zonedSchedule(
            id: notificationId,
            title: '💸 ${reminder.title}',
            body: '₹${reminder.amount.toStringAsFixed(0)} due — Day ${reminder.dayStart}–${reminder.dayEnd}',
            scheduledDate: scheduledDate,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'duezy_reminders',
                'Bill Reminders',
                channelDescription: 'Daily reminders for upcoming bills and EMIs',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                color: _getCategoryColor(reminder.category),
                enableVibration: true,
                playSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: reminder.id,
          );
        }
      }
    }
  }

  // Cancel notifications scheduled for a specific reminder.
  Future<void> cancelReminderNotifications(String reminderId) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);

    for (int monthOffset = 0; monthOffset <= 1; monthOffset++) {
      int year = now.year;
      int month = now.month + monthOffset;
      if (month > 12) {
        month -= 12;
        year += 1;
      }

      for (int day = 1; day <= 31; day++) {
        final notificationId = _generateNotificationId(
          reminderId,
          year,
          month,
          day,
        );
        await _plugin.cancel(id: notificationId);
      }
    }
  }

  // Generate deterministic ID for notification scheduling.
  int _generateNotificationId(
    String reminderId,
    int year,
    int month,
    int day,
  ) {
    final key = '${reminderId}_${year}_${month}_$day';
    return key.hashCode & 0x7FFFFFFF;
  }

  // Map category to accent color.
  Color _getCategoryColor(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.emi:
        return const Color(0xFF5C6BC0);
      case ReminderCategory.subscription:
        return const Color(0xFF26A69A);
      case ReminderCategory.bill:
        return const Color(0xFFFFA726);
      case ReminderCategory.custom:
        return const Color(0xFFAB47BC);
    }
  }
}
