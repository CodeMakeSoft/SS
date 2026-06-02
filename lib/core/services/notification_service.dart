import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    await Permission.notification.request();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // Setting for iOS can be added here if needed
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();

    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'smartsync_race_alerts', 
      'Race Alerts',
      channelDescription: 'Important alerts about the current race',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: const Color(0xFF4A90E2), // Will need import 'package:flutter/material.dart'; or just use a hex integer value
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
