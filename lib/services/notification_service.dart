import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> scheduleForSubscriptions(List<Subscription> subscriptions) async {
    await init();
    await _plugin.cancelAll();
    for (final subscription in subscriptions) {
      final scheduled = _buildReminderTime(subscription.nextBillingDate);
      if (scheduled == null) {
        continue;
      }
      final id = _notificationId(subscription);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'subscription_reminders',
          'Subscription reminders',
          channelDescription: 'Reminders about upcoming subscription charges',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        id,
        'Скоро списание',
        '${subscription.name} • ${subscription.price.toStringAsFixed(2)} RUB завтра',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  tz.TZDateTime? _buildReminderTime(DateTime nextBillingDate) {
    final now = tz.TZDateTime.now(tz.local);
    final base = DateTime(nextBillingDate.year, nextBillingDate.month, nextBillingDate.day)
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 13));
    final scheduled = tz.TZDateTime.from(base, tz.local);
    if (scheduled.isBefore(now)) {
      return null;
    }
    return scheduled;
  }

  int _notificationId(Subscription subscription) {
    if (subscription.id != null) {
      return subscription.id!;
    }
    final raw = '${subscription.name}-${subscription.nextBillingDate.toIso8601String()}';
    return _hashToInt(raw);
  }

  int _hashToInt(String value) {
    final bytes = utf8.encode(value);
    var hash = 0;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
