import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alert_evaluator.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _ready = true;
  }

  Future<void> showAlerts(List<EnergyAlert> alerts) async {
    if (!_ready || alerts.isEmpty) return;
    for (var i = 0; i < alerts.length; i++) {
      final alert = alerts[i];
      const androidDetails = AndroidNotificationDetails(
        'energy_alerts',
        'Alertes énergie',
        channelDescription: 'Alertes de solde, autonomie et consommation',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(2000 + i, alert.title, alert.message, details);
    }
  }
}
