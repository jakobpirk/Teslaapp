import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../core/di/injection_container.dart' as di;
import '../core/domain/usecases/get_vehicle_state.dart';
import '../core/domain/usecases/charging_operations.dart';
import 'notification_service.dart';

// Background task callback - must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await di.init();

      final monitor = ChargingMonitorService();
      await monitor.checkChargingState();

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

class ChargingMonitorService {
  static final ChargingMonitorService _instance = ChargingMonitorService._internal();
  factory ChargingMonitorService() => _instance;
  ChargingMonitorService._internal();

  final NotificationService _notificationService = NotificationService();

  static const String _keyLastChargingState = 'last_charging_state';
  static const String _keyLastBatteryLevel = 'last_battery_level';
  static const String _keyMaxChargeLimit = 'max_charge_limit';
  static const String _keyMonitoringEnabled = 'monitoring_enabled';
  static const String _taskName = 'charging_monitor_task';

  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  Future<void> startMonitoring() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register periodic task to check charging state every 15 minutes
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonitoringEnabled, true);
  }

  Future<void> stopMonitoring() async {
    await Workmanager().cancelByUniqueName(_taskName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonitoringEnabled, false);
  }

  Future<bool> isMonitoringEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMonitoringEnabled) ?? false;
  }

  Future<void> checkChargingState() async {
    try {
      final getVehicleState = di.sl<GetVehicleState>();
      final stopCharging = di.sl<StopCharging>();
      final prefs = await SharedPreferences.getInstance();

      // Get current vehicle state
      final result = await getVehicleState();

      result.fold(
        (failure) {
          print('Failed to get vehicle state: $failure');
        },
        (vehicle) async {
          final isCharging = vehicle.chargingState == 'Charging';
          final batteryLevel = vehicle.batteryLevel;

          // Get stored values
          final wasCharging = prefs.getBool(_keyLastChargingState) ?? false;
          final lastBatteryLevel = prefs.getInt(_keyLastBatteryLevel) ?? 0;
          final maxChargeLimit = prefs.getInt(_keyMaxChargeLimit);

          // Detect charging started
          if (isCharging && !wasCharging) {
            await _notificationService.showChargingStartedNotification(
              currentBattery: batteryLevel,
              maxChargeLimit: maxChargeLimit,
            );
          }

          // Detect charging stopped
          if (!isCharging && wasCharging) {
            final reason = batteryLevel >= 100
                ? 'Fully charged'
                : maxChargeLimit != null && batteryLevel >= maxChargeLimit
                    ? 'Target reached'
                    : 'Charging interrupted';

            await _notificationService.showChargingStoppedNotification(
              currentBattery: batteryLevel,
              reason: reason,
            );
          }

          // Check if max charge limit reached
          if (isCharging && maxChargeLimit != null && batteryLevel >= maxChargeLimit) {
            // Stop charging
            await stopCharging();

            await _notificationService.showMaxChargeLimitReachedNotification(
              currentBattery: batteryLevel,
              maxChargeLimit: maxChargeLimit,
            );
          }

          // Show progress notification during charging
          if (isCharging && maxChargeLimit != null && batteryLevel < maxChargeLimit) {
            // Only update if battery level changed
            if (batteryLevel != lastBatteryLevel) {
              await _notificationService.showChargingProgressNotification(
                currentBattery: batteryLevel,
                maxChargeLimit: maxChargeLimit,
              );
            }
          } else {
            // Cancel progress notification when not charging
            await _notificationService.cancelNotification(4);
          }

          // Store current state
          await prefs.setBool(_keyLastChargingState, isCharging);
          await prefs.setInt(_keyLastBatteryLevel, batteryLevel);
        },
      );
    } catch (e) {
      print('Error checking charging state: $e');
    }
  }

  Future<void> setMaxChargeLimit(int? limit) async {
    final prefs = await SharedPreferences.getInstance();
    if (limit != null) {
      await prefs.setInt(_keyMaxChargeLimit, limit);
    } else {
      await prefs.remove(_keyMaxChargeLimit);
    }
  }

  Future<int?> getMaxChargeLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxChargeLimit);
  }

  Future<void> clearStoredState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastChargingState);
    await prefs.remove(_keyLastBatteryLevel);
  }
}
