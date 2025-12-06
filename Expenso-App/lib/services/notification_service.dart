import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../add_expense_page.dart';
import '../main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();

    await setupFlutterNotifications();

    const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: androidInitializationSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final data = _parsePayload(details.payload);
        if (data != null && data['type'] == 'chat') {
          _handleNavigation('chat');
        }
      },
    );

    await _setupMessageHandlers();

    final token = await _messaging.getToken();
    print('FCM Token: $token');

    await subscribeToTopic('all_devices');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM Permission Status: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          print('Android 13+ notification permission status: $result');
        }
      }
    }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(channel);

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
      _showDialogWithoutNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'chat') {
        _handleNavigation('chat');
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data['type'] == 'chat') {
      _handleNavigation('chat');
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

      await _localNotifications.show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );

  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          channelDescription: 'Your channel description',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Optional: if you want it daily
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  void _showDialogWithoutNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    final title = notification?.title ?? 'Notification';
    final body = notification?.body ?? 'You have a new message';
    final type = message.data['type'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNavigation(type);
              },
              child: const Text('View'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic>? _parsePayload(String? payload) {
    try {
      if (payload == null) return null;
      return jsonDecode(payload);
    } catch (e) {
      print('Error decoding payload: $e');
      return null;
    }
  }

  void _handleNavigation(String type) {
    if (type == 'chat') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => ExpenseScreen()),
      );
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print("Subscribed to $topic");
  }

  Future<void> sendNotification(String title, String body) async {
    // Reminder: NEVER hardcode tokens in production.
    String accessToken = 'ya29.c.c0ASRK0Gbw1fgRAe1RoVpRbhuxqUBqiw9cc6xS2jizDcke8Xg6XC3iu1lpGjVXokci_3QvvzsrQimpUqbug4GL3O3PhsDIOZbSnfKemokNpWHdO_4Ibm75F1FnhT1l06NGehNsxQvJL5oaf9-efUNd-gxEFKZAAmfiwhxcjsPVCu5Xel7jjQVsXx1QcTjLwW1NLEwFrgdTqgZ2YWlqp95V4KUJTAeRXphsX9FhksL6BhNy6Oa-xRe___G8N4cWgZrcbrS-KvAtN0TjlnFNCXA3uexYUfREHc57Tk8M_obaYtSvA69lHYJiKd7pmVnM8XRlzDycFOzM3bXjYmGzbozbPc0sraLEqPWwMVRosh1OCUFuN7_7gbY4uZyPVQH387DXXmy5Z601q6X4zc6t8XsfWrvaliJjFYO9x585qu2pJlOp5rR3m7Sg95yab66XR2eStbdmXkuhnxrtJffMZfB_rvQX5Vi9nbqxkw40o38eni89wueOpwzlJprita56yx-xrJBWka2I9Xr78wjj8ulmdygJ6vmRWjIwWemnMm1UJW5dy6wgpioZjcQuFo_wMu91l8QvS-jIczqZrfQ-sj2eI0r7n0W9hnrUU8Jevx3JFbii__x9sry3V_g5rJqQ_lvnQdIqp3FdgROaSf-byYB5b23sFg-n65ukl2a9ZIIBhfc4Fx4mxXVYk2Bzr0qh7J97lQRbjk_BMxrp4I9rwIR-16bI_4e-7xrnUQx64t2SzXSklQvqXIv-u9ch92m4Wh7eo2zxzmwb8lYQ1pnJMa5Qu9sQnXu1adYVoB_IwZrkIdwq3ca_kbSJpifcc6kJVwwRVZlrXj51SwlqyjMBZ8Vv_uq33moSak-ozhI0ylmSJ5dhswcg2_70hp8bhl_MgVguiUgMnnouXUmgua0lZJQduQ8VvYhYWwkvJ1eli_qJMiXfhW8czyat-8eWn7FdiQVjbZtaWv-W7aYcVOdIsa8-2d6cnay-s_U3wR6IYz4icg138VVsXY8qMU9';
    final messagePayload = {
      'message': {
        'topic': "all_devices",
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'type': "chat"
        },
        'android': {
          'priority': "high",
          'notification': {
            'channel_id': "high_importance_channel",
          }
        }
      }
    };

    final url = 'https://fcm.googleapis.com/v1/projects/wallet-13f58/messages:send';
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(messagePayload),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Error sending notification: ${response.body}');
    }
  }
}
