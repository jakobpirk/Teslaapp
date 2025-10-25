import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage charging settings and max charge limits
/// Works with Firebase Cloud Functions for background monitoring
class ChargingSettingsService {
  static final ChargingSettingsService _instance = ChargingSettingsService._internal();
  factory ChargingSettingsService() => _instance;
  ChargingSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _keyMaxChargeLimit = 'max_charge_limit';
  static const String _keyMonitoringEnabled = 'monitoring_enabled';
  static const String _keyLastBatteryLevel = 'last_battery_level';

  /// Set max charge limit (for auto-stop)
  Future<void> setMaxChargeLimit(int? limit, String? vehicleId) async {
    final prefs = await SharedPreferences.getInstance();

    if (limit != null) {
      await prefs.setInt(_keyMaxChargeLimit, limit);

      // Save to Firestore for cloud function access
      if (vehicleId != null) {
        await _saveToFirestore(vehicleId, limit);
      }
    } else {
      await prefs.remove(_keyMaxChargeLimit);

      // Remove from Firestore
      if (vehicleId != null) {
        await _removeFromFirestore(vehicleId);
      }
    }
  }

  /// Get max charge limit
  Future<int?> getMaxChargeLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxChargeLimit);
  }

  /// Enable monitoring (registers with cloud function)
  Future<void> enableMonitoring(String vehicleId, String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonitoringEnabled, true);

    // Register vehicle for monitoring in Firestore
    await _firestore.collection('charging_monitors').doc(vehicleId).set({
      'vehicleId': vehicleId,
      'fcmToken': fcmToken,
      'enabled': true,
      'maxChargeLimit': await getMaxChargeLimit(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Disable monitoring
  Future<void> disableMonitoring(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonitoringEnabled, false);

    // Update Firestore
    await _firestore.collection('charging_monitors').doc(vehicleId).update({
      'enabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if monitoring is enabled
  Future<bool> isMonitoringEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMonitoringEnabled) ?? false;
  }

  /// Save last battery level (for detecting changes)
  Future<void> saveLastBatteryLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastBatteryLevel, level);
  }

  /// Get last battery level
  Future<int?> getLastBatteryLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastBatteryLevel);
  }

  /// Save max charge limit to Firestore
  Future<void> _saveToFirestore(String vehicleId, int limit) async {
    try {
      await _firestore.collection('charging_monitors').doc(vehicleId).set({
        'vehicleId': vehicleId,
        'maxChargeLimit': limit,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to save max charge limit to Firestore: $e');
    }
  }

  /// Remove max charge limit from Firestore
  Future<void> _removeFromFirestore(String vehicleId) async {
    try {
      await _firestore.collection('charging_monitors').doc(vehicleId).update({
        'maxChargeLimit': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to remove max charge limit from Firestore: $e');
    }
  }

  /// Update FCM token in Firestore
  Future<void> updateFcmToken(String vehicleId, String fcmToken) async {
    try {
      await _firestore.collection('charging_monitors').doc(vehicleId).update({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  /// Get vehicle settings from Firestore
  Future<Map<String, dynamic>?> getVehicleSettings(String vehicleId) async {
    try {
      final doc = await _firestore.collection('charging_monitors').doc(vehicleId).get();
      return doc.data();
    } catch (e) {
      print('Failed to get vehicle settings: $e');
      return null;
    }
  }
}
