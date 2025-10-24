import 'package:flutter/foundation.dart';
import '../../../../core/data/datasources/user_settings_http_datasource.dart';
import '../../../../core/data/datasources/electricity_provider_http_datasource.dart';
import '../../../../core/data/models/user_settings_dto.dart';
import '../../../../core/data/models/electricity_provider_dto.dart';

class UserSettingsProvider with ChangeNotifier {
  final UserSettingsHttpDataSource _settingsDataSource;
  final ElectricityProviderHttpDataSource _providerDataSource;
  String? _token;

  UserSettingsDto? _settings;
  UserProfileDto? _profile;
  List<ElectricityProviderDto> _availableProviders = [];
  bool _isLoading = false;
  String? _error;

  UserSettingsProvider(
    this._settingsDataSource,
    this._providerDataSource,
  );

  // Getters
  UserSettingsDto? get settings => _settings;
  UserProfileDto? get profile => _profile;
  List<ElectricityProviderDto> get availableProviders => _availableProviders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTessieApiKey => _settings?.hasTessieApiKey ?? false;
  bool get hasElectricityProvider => _settings?.electricityProvider != null;
  ElectricityProviderDto? get selectedProvider => _settings?.electricityProvider;

  /// Set authentication token
  void setToken(String token) {
    _token = token;
  }

  /// Load user settings
  Future<void> loadSettings() async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _settingsDataSource.getSettings(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile
  Future<void> loadProfile() async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _settingsDataSource.getProfile(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load available electricity providers
  Future<void> loadAvailableProviders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableProviders = await _providerDataSource.getProviders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update Tessie API key
  Future<bool> updateTessieApiKey(String apiKey) async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _settingsDataSource.updateTessieApiKey(_token!, apiKey);

      // Reload settings to get updated state
      await loadSettings();

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

  /// Remove Tessie API key
  Future<bool> removeTessieApiKey() async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _settingsDataSource.removeTessieApiKey(_token!);

      // Reload settings
      await loadSettings();

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

  /// Update electricity provider
  Future<bool> updateElectricityProvider(String providerId) async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _settingsDataSource.updateElectricityProvider(_token!, providerId);

      // Reload settings
      await loadSettings();

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

  /// Initialize settings (load everything needed)
  Future<void> initialize() async {
    await Future.wait([
      loadSettings(),
      loadProfile(),
      loadAvailableProviders(),
    ]);
  }

  /// Clear all data
  void clear() {
    _settings = null;
    _profile = null;
    _availableProviders = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
