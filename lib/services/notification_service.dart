import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;

    // Request permissions
    await requestPermissions();
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to charging screen
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showChargingStartedNotification({
    required int currentBattery,
    required int? maxChargeLimit,
  }) async {
    final limitText = maxChargeLimit != null
        ? ' Target: $maxChargeLimit%'
        : '';

    await _notifications.show(
      1, // notification ID
      'Charging Started',
      'Battery at $currentBattery%.$limitText',
      _getNotificationDetails(),
      payload: 'charging_started',
    );
  }

  Future<void> showChargingStoppedNotification({
    required int currentBattery,
    required String reason,
  }) async {
    await _notifications.show(
      2, // notification ID
      'Charging Stopped',
      'Battery at $currentBattery%. $reason',
      _getNotificationDetails(),
      payload: 'charging_stopped',
    );
  }

  Future<void> showMaxChargeLimitReachedNotification({
    required int currentBattery,
    required int maxChargeLimit,
  }) async {
    await _notifications.show(
      3, // notification ID
      'Charge Limit Reached',
      'Battery reached $currentBattery% (target: $maxChargeLimit%). Charging stopped automatically.',
      _getNotificationDetails(
        importance: Importance.high,
        priority: Priority.high,
      ),
      payload: 'max_charge_reached',
    );
  }

  Future<void> showChargingProgressNotification({
    required int currentBattery,
    required int maxChargeLimit,
  }) async {
    final progress = ((currentBattery / maxChargeLimit) * 100).round();

    await _notifications.show(
      4, // notification ID
      'Charging Progress',
      'Battery: $currentBattery% / $maxChargeLimit%',
      _getProgressNotificationDetails(
        progress: progress,
        maxProgress: 100,
      ),
      payload: 'charging_progress',
    );
  }

  NotificationDetails _getNotificationDetails({
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) {
    final androidDetails = AndroidNotificationDetails(
      'charging_channel',
      'Charging Notifications',
      channelDescription: 'Notifications for charging events',
      importance: importance,
      priority: priority,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails _getProgressNotificationDetails({
    required int progress,
    required int maxProgress,
  }) {
    final androidDetails = AndroidNotificationDetails(
      'charging_progress_channel',
      'Charging Progress',
      channelDescription: 'Shows charging progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
