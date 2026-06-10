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

    const String groupKey = 'com.smartsync.app.RACE_ALERTS';
    const String channelId = 'smartsync_race_alerts';

    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      channelId, 
      'Race Alerts',
      channelDescription: 'Important alerts about the current race',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF4A90E2),
      groupKey: groupKey,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // 1. Mostrar la notificación individual
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );

    // 2. Mostrar/actualizar la notificación de resumen de grupo
    const AndroidNotificationDetails summaryNotificationDetails = AndroidNotificationDetails(
      channelId,
      'Race Alerts',
      channelDescription: 'Important alerts about the current race',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF4A90E2),
      groupKey: groupKey,
      setAsGroupSummary: true,
    );

    const NotificationDetails summaryDetails = NotificationDetails(
      android: summaryNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // ID fijo para el resumen
      'Notificaciones de SmartSync',
      'Alertas de carrera activas',
      summaryDetails,
    );
  }
}
