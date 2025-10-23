import 'package:flutter/foundation.dart';
import '../models/vehicle_state.dart';
import '../services/tessie_api_service.dart';

class VehicleProvider with ChangeNotifier {
  final TessieApiService _apiService;

  VehicleState? _vehicleState;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastRefresh;

  VehicleProvider(this._apiService);

  VehicleState? get vehicleState => _vehicleState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastRefresh => _lastRefresh;

  bool get needsRefresh {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) > const Duration(minutes: 5);
  }

  Future<void> refreshVehicleState() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicleState = await _apiService.getVehicleState();
      _lastRefresh = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> wakeVehicle() async {
    await _executeCommand(() => _apiService.wakeVehicle());
  }

  Future<void> lockVehicle() async {
    await _executeCommand(() => _apiService.lockVehicle());
  }

  Future<void> unlockVehicle() async {
    await _executeCommand(() => _apiService.unlockVehicle());
  }

  Future<void> startClimate() async {
    await _executeCommand(() => _apiService.startClimate());
  }

  Future<void> stopClimate() async {
    await _executeCommand(() => _apiService.stopClimate());
  }

  Future<void> setTemperature(double temp) async {
    await _executeCommand(() => _apiService.setTemperature(temp));
  }

  Future<void> startCharging() async {
    await _executeCommand(() => _apiService.startCharging());
  }

  Future<void> stopCharging() async {
    await _executeCommand(() => _apiService.stopCharging());
  }

  Future<void> setChargeLimit(int percent) async {
    await _executeCommand(() => _apiService.setChargeLimit(percent));
  }

  Future<void> flashLights() async {
    await _executeCommand(() => _apiService.flashLights());
  }

  Future<void> honkHorn() async {
    await _executeCommand(() => _apiService.honkHorn());
  }

  Future<void> toggleSentryMode() async {
    if (_vehicleState?.isSentryMode == true) {
      await _executeCommand(() => _apiService.disableSentryMode());
    } else {
      await _executeCommand(() => _apiService.enableSentryMode());
    }
  }

  Future<void> openFrunk() async {
    await _executeCommand(() => _apiService.openFrunk());
  }

  Future<void> openTrunk() async {
    await _executeCommand(() => _apiService.openTrunk());
  }

  Future<void> _executeCommand(Future<Map<String, dynamic>> Function() command) async {
    try {
      await command();
      // Refresh state after command
      await Future.delayed(const Duration(seconds: 2));
      await refreshVehicleState();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
