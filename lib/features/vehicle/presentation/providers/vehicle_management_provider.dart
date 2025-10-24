import 'package:flutter/foundation.dart';
import '../../../../core/data/datasources/vehicle_http_datasource.dart';
import '../../../../core/data/models/vehicle_model_dto.dart';

class VehicleManagementProvider with ChangeNotifier {
  final VehicleHttpDataSource _dataSource;
  String? _token;

  List<VehicleModelDto> _vehicles = [];
  VehicleModelDto? _selectedVehicle;
  bool _isLoading = false;
  String? _error;

  VehicleManagementProvider(this._dataSource);

  // Getters
  List<VehicleModelDto> get vehicles => _vehicles;
  List<VehicleModelDto> get activeVehicles =>
      _vehicles.where((v) => v.isActive).toList();
  VehicleModelDto? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasVehicles => _vehicles.isNotEmpty;
  bool get hasSelectedVehicle => _selectedVehicle != null;

  /// Set authentication token
  void setToken(String token) {
    _token = token;
  }

  /// Select a vehicle
  void selectVehicle(VehicleModelDto vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  /// Clear selected vehicle
  void clearSelection() {
    _selectedVehicle = null;
    notifyListeners();
  }

  /// Load all vehicles
  Future<void> loadVehicles() async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _dataSource.getVehicles(_token!);

      // Auto-select first active vehicle if none selected
      if (_selectedVehicle == null && _vehicles.isNotEmpty) {
        _selectedVehicle = _vehicles.firstWhere(
          (v) => v.isActive,
          orElse: () => _vehicles.first,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load only active vehicles
  Future<void> loadActiveVehicles() async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _dataSource.getActiveVehicles(_token!);

      if (_selectedVehicle == null && _vehicles.isNotEmpty) {
        _selectedVehicle = _vehicles.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new vehicle
  Future<bool> addVehicle(CreateVehicleDto vehicleDto) async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newVehicle = await _dataSource.createVehicle(_token!, vehicleDto);
      _vehicles.add(newVehicle);

      // Select the newly added vehicle
      _selectedVehicle = newVehicle;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a vehicle
  Future<bool> updateVehicle(
    String vehicleId,
    UpdateVehicleDto vehicleDto,
  ) async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _dataSource.updateVehicle(
        _token!,
        vehicleId,
        vehicleDto,
      );

      // Update in list
      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles[index] = updated;
      }

      // Update selected if it's the same vehicle
      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = updated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete (deactivate) a vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dataSource.deleteVehicle(_token!, vehicleId);

      // Remove from list or reload
      await loadVehicles();

      // Clear selection if deleted vehicle was selected
      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get vehicle statistics
  Future<Map<String, dynamic>?> getVehicleStatistics(String vehicleId) async {
    if (_token == null) return null;

    try {
      return await _dataSource.getVehicleStatistics(_token!, vehicleId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear all data
  void clear() {
    _vehicles = [];
    _selectedVehicle = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
