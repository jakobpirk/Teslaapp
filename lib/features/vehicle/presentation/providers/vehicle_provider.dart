import 'package:flutter/foundation.dart';
import '../../../../core/domain/entities/vehicle_entity.dart';
import '../../../../core/domain/usecases/get_vehicle_state.dart';
import '../../../../core/domain/usecases/wake_vehicle.dart';
import '../../../../core/domain/usecases/vehicle_lock_operations.dart';
import '../../../../core/domain/usecases/vehicle_alert_operations.dart';
import '../../../../core/domain/usecases/climate_operations.dart';
import '../../../../core/domain/usecases/charging_operations.dart';
import '../../../../core/domain/usecases/security_operations.dart';
import '../../../../core/domain/usecases/vehicle_access_operations.dart';
import '../../../../services/firebase_notification_service.dart';
import '../../../../services/charging_settings_service.dart';

/// Provider for vehicle state and operations
/// Uses use cases to interact with the domain layer
class VehicleProvider with ChangeNotifier {
  // Use cases
  final GetVehicleState getVehicleState;
  final WakeVehicle wakeVehicle;
  final LockVehicle lockVehicle;
  final UnlockVehicle unlockVehicle;
  final FlashLights flashLights;
  final HonkHorn honkHorn;
  final StartClimate startClimate;
  final StopClimate stopClimate;
  final SetTemperature setTemperature;
  final EnableMaxDefrost enableMaxDefrost;
  final DisableMaxDefrost disableMaxDefrost;
  final SetSeatHeater setSeatHeater;
  final SetSeatCooler setSeatCooler;
  final EnableSteeringWheelHeater enableSteeringWheelHeater;
  final DisableSteeringWheelHeater disableSteeringWheelHeater;
  final StartCharging startCharging;
  final StopCharging stopCharging;
  final SetChargeLimit setChargeLimit;
  final EnableSentryMode enableSentryMode;
  final DisableSentryMode disableSentryMode;
  final OpenFrunk openFrunk;
  final OpenTrunk openTrunk;
  final VentWindows ventWindows;
  final CloseWindows closeWindows;

  // State
  VehicleEntity? _vehicleState;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastRefresh;

  // Firebase services
  final FirebaseNotificationService _notificationService = FirebaseNotificationService();
  final ChargingSettingsService _chargingSettings = ChargingSettingsService();

  VehicleProvider({
    required this.getVehicleState,
    required this.wakeVehicle,
    required this.lockVehicle,
    required this.unlockVehicle,
    required this.flashLights,
    required this.honkHorn,
    required this.startClimate,
    required this.stopClimate,
    required this.setTemperature,
    required this.enableMaxDefrost,
    required this.disableMaxDefrost,
    required this.setSeatHeater,
    required this.setSeatCooler,
    required this.enableSteeringWheelHeater,
    required this.disableSteeringWheelHeater,
    required this.startCharging,
    required this.stopCharging,
    required this.setChargeLimit,
    required this.enableSentryMode,
    required this.disableSentryMode,
    required this.openFrunk,
    required this.openTrunk,
    required this.ventWindows,
    required this.closeWindows,
  });

  // Getters
  VehicleEntity? get vehicleState => _vehicleState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastRefresh => _lastRefresh;

  bool get needsRefresh {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) > const Duration(minutes: 5);
  }

  /// Refresh vehicle state
  Future<void> refreshVehicleState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getVehicleState.call();

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (vehicle) {
        _vehicleState = vehicle;
        _lastRefresh = DateTime.now();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Wake vehicle
  Future<void> wake() async {
    await _executeCommand(() => wakeVehicle.call());
  }

  /// Lock vehicle
  Future<void> lock() async {
    await _executeCommand(() => lockVehicle.call());
  }

  /// Unlock vehicle
  Future<void> unlock() async {
    await _executeCommand(() => unlockVehicle.call());
  }

  /// Flash lights
  Future<void> flash() async {
    await _executeCommand(() => flashLights.call());
  }

  /// Honk horn
  Future<void> honk() async {
    await _executeCommand(() => honkHorn.call());
  }

  /// Start climate control
  Future<void> startClimateControl() async {
    await _executeCommand(() => startClimate.call());
  }

  /// Stop climate control
  Future<void> stopClimateControl() async {
    await _executeCommand(() => stopClimate.call());
  }

  /// Set temperature
  Future<void> setClimateTemperature(double temperature) async {
    await _executeCommand(
      () => setTemperature.call(TemperatureParams(temperature)),
    );
  }

  /// Enable max defrost
  Future<void> enableDefrost() async {
    await _executeCommand(() => enableMaxDefrost.call());
  }

  /// Disable max defrost
  Future<void> disableDefrost() async {
    await _executeCommand(() => disableMaxDefrost.call());
  }

  /// Set seat heater
  Future<void> setHeater(int seat, int level) async {
    await _executeCommand(
      () => setSeatHeater.call(SeatControlParams(seat, level)),
    );
  }

  /// Set seat cooler
  Future<void> setCooler(int seat, int level) async {
    await _executeCommand(
      () => setSeatCooler.call(SeatControlParams(seat, level)),
    );
  }

  /// Enable steering wheel heater
  Future<void> enableWheelHeater() async {
    await _executeCommand(() => enableSteeringWheelHeater.call());
  }

  /// Disable steering wheel heater
  Future<void> disableWheelHeater() async {
    await _executeCommand(() => disableSteeringWheelHeater.call());
  }

  /// Start charging
  Future<void> startCharge() async {
    await _executeCommand(() => startCharging.call());
  }

  /// Stop charging
  Future<void> stopCharge() async {
    await _executeCommand(() => stopCharging.call());
  }

  /// Set charge limit
  Future<void> setLimit(int limit) async {
    await _executeCommand(
      () => setChargeLimit.call(ChargeLimitParams(limit)),
    );
  }

  /// Set max charge limit (for auto-stop)
  /// vehicleId should be the VIN or unique vehicle identifier
  Future<void> setMaxChargeLimit(int? limit, {String? vehicleId}) async {
    await _chargingSettings.setMaxChargeLimit(limit, vehicleId);

    // Update current battery level if we have vehicle state
    if (_vehicleState != null) {
      await _chargingSettings.saveLastBatteryLevel(_vehicleState!.batteryLevel);
    }

    notifyListeners();
  }

  /// Get max charge limit
  Future<int?> getMaxChargeLimit() async {
    return await _chargingSettings.getMaxChargeLimit();
  }

  /// Enable charging notifications
  /// vehicleId should be the VIN or unique vehicle identifier
  Future<void> enableChargingNotifications({String? vehicleId}) async {
    await _notificationService.initialize();

    // Get FCM token
    final fcmToken = await _notificationService.getFcmToken();

    if (fcmToken != null && vehicleId != null) {
      // Enable monitoring with Firebase Cloud Functions
      await _chargingSettings.enableMonitoring(vehicleId, fcmToken);

      // Subscribe to vehicle-specific notifications
      await _notificationService.subscribeToVehicleUpdates(vehicleId);
    }

    await _notificationService.enableNotifications();
    notifyListeners();
  }

  /// Disable charging notifications
  Future<void> disableChargingNotifications({String? vehicleId}) async {
    if (vehicleId != null) {
      await _chargingSettings.disableMonitoring(vehicleId);
      await _notificationService.unsubscribeFromVehicleUpdates(vehicleId);
    }

    await _notificationService.disableNotifications();
    notifyListeners();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Get FCM token (for debugging)
  Future<String?> getFcmToken() async {
    return await _notificationService.getFcmToken();
  }

  /// Toggle sentry mode
  Future<void> toggleSentryMode() async {
    if (_vehicleState?.isSentryMode == true) {
      await _executeCommand(() => disableSentryMode.call());
    } else {
      await _executeCommand(() => enableSentryMode.call());
    }
  }

  /// Open frunk
  Future<void> openFrontTrunk() async {
    await _executeCommand(() => openFrunk.call());
  }

  /// Open trunk
  Future<void> openRearTrunk() async {
    await _executeCommand(() => openTrunk.call());
  }

  /// Vent windows
  Future<void> vent() async {
    await _executeCommand(() => ventWindows.call());
  }

  /// Close windows
  Future<void> close() async {
    await _executeCommand(() => closeWindows.call());
  }

  /// Execute command with error handling and auto-refresh
  Future<void> _executeCommand(Future<dynamic> Function() command) async {
    try {
      final result = await command();

      // Handle Either result
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
          throw Exception(failure.message);
        },
        (_) {
          // Success - refresh after delay
        },
      );

      // Refresh state after command
      await Future.delayed(const Duration(seconds: 2));
      await refreshVehicleState();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
