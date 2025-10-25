import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  // Handle the notification in the background
  final service = FirebaseNotificationService();
  await service.handleBackgroundMessage(message);
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  static const String _keyFcmToken = 'fcm_token';
  static const String _keyNotificationsEnabled = 'fcm_notifications_enabled';

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permissions
    await requestPermissions();

    // Initialize local notifications for foreground messages
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Save token to SharedPreferences
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFcmToken, _fcmToken!);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFcmToken, newToken);

      // TODO: Send updated token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    // Request FCM permission (iOS)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Request Android notification permission
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted && settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'Charging Notification',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Processing background message: ${message.messageId}');
    // Background messages are automatically displayed by FCM
    // Additional processing can be done here if needed
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification opened: ${message.messageId}');
    // Navigate to appropriate screen based on message data
    final data = message.data;
    // TODO: Implement navigation based on data['type']
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // TODO: Implement navigation
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'charging_channel',
      'Charging Notifications',
      channelDescription: 'Notifications for charging events',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data?['type'],
    );
  }

  String? get fcmToken => _fcmToken;

  Future<String?> getFcmToken() async {
    if (_fcmToken != null) return _fcmToken;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, true);

    // Subscribe to charging notifications topic
    await _firebaseMessaging.subscribeToTopic('charging_notifications');
  }

  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, false);

    // Unsubscribe from charging notifications topic
    await _firebaseMessaging.unsubscribeFromTopic('charging_notifications');
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  Future<void> subscribeToVehicleUpdates(String vehicleId) async {
    // Subscribe to vehicle-specific topic for targeted notifications
    await _firebaseMessaging.subscribeToTopic('vehicle_$vehicleId');
  }

  Future<void> unsubscribeFromVehicleUpdates(String vehicleId) async {
    await _firebaseMessaging.unsubscribeFromTopic('vehicle_$vehicleId');
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
