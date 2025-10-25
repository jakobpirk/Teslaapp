import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/data/datasources/smart_charging_http_datasource.dart';
import '../../../../core/data/models/pricing_history_dto.dart';
import '../../../../core/data/models/charging_recommendation_dto.dart';
import '../../../../constants/backend_api_constants.dart';

class SmartChargingProvider with ChangeNotifier {
  final SmartChargingHttpDataSource _dataSource;

  List<PricingHistoryDto> _pricingHistory = [];
  ChargingRecommendationDto? _currentRecommendation;
  bool _isLoading = false;
  bool _isGeneratingRecommendation = false;
  String? _error;
  DateTime? _lastPricingUpdate;
  DateTime? _lastRecommendationUpdate;

  SmartChargingProvider({SmartChargingHttpDataSource? dataSource})
      : _dataSource = dataSource ??
            SmartChargingHttpDataSource(
              dio: Dio(),
              baseUrl: BackendApiConstants.baseUrl,
            );

  // Getters
  List<PricingHistoryDto> get pricingHistory => _pricingHistory;
  ChargingRecommendationDto? get currentRecommendation => _currentRecommendation;
  bool get isLoading => _isLoading;
  bool get isGeneratingRecommendation => _isGeneratingRecommendation;
  String? get error => _error;
  DateTime? get lastPricingUpdate => _lastPricingUpdate;
  DateTime? get lastRecommendationUpdate => _lastRecommendationUpdate;

  /// Check if we should charge now based on current recommendation
  bool get shouldChargeNow =>
      _currentRecommendation?.shouldChargeNow ?? false;

  /// Get estimated cost savings
  double get estimatedSavings =>
      _currentRecommendation?.costSavings ?? 0.0;

  /// Get confidence score
  int get confidenceScore =>
      _currentRecommendation?.confidenceScore ?? 0;

  /// Load pricing for today and tomorrow
  Future<void> loadTodayTomorrowPricing() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dataSource.getTodayTomorrowPricing();

      _pricingHistory = response.data;
      _lastPricingUpdate = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to load pricing: $e';
      _pricingHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get current electricity price
  Future<PricingHistoryDto?> getCurrentPrice() async {
    try {
      return await _dataSource.getCurrentPricing();
    } catch (e) {
      _error = 'Failed to get current price: $e';
      notifyListeners();
      return null;
    }
  }

  /// Generate a new charging recommendation
  Future<void> generateRecommendation({
    required String vehicleId,
    DateTime? requiredBy,
    double? energyNeeded,
  }) async {
    _isGeneratingRecommendation = true;
    _error = null;
    notifyListeners();

    try {
      final recommendation = await _dataSource.generateRecommendation(
        vehicleId: vehicleId,
        requiredBy: requiredBy,
        energyNeeded: energyNeeded,
      );

      _currentRecommendation = recommendation;
      _lastRecommendationUpdate = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Failed to generate recommendation: $e';
      _currentRecommendation = null;
    } finally {
      _isGeneratingRecommendation = false;
      notifyListeners();
    }
  }

  /// Get the latest recommendation for a vehicle
  Future<void> loadLatestRecommendation(String vehicleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dataSource.getLatestRecommendation(vehicleId);

      if (response != null) {
        _currentRecommendation = response.recommendation;
        _lastRecommendationUpdate = DateTime.now();
        _error = null;
      } else {
        _currentRecommendation = null;
      }
    } catch (e) {
      _error = 'Failed to load recommendation: $e';
      _currentRecommendation = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark current recommendation as executed
  Future<void> markRecommendationExecuted() async {
    if (_currentRecommendation == null) return;

    try {
      final updated = await _dataSource.markRecommendationExecuted(
        _currentRecommendation!.id,
      );
      _currentRecommendation = updated;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark recommendation as executed: $e';
      notifyListeners();
    }
  }

  /// Update recommendation status
  Future<void> updateRecommendationStatus(String status) async {
    if (_currentRecommendation == null) return;

    try {
      final updated = await _dataSource.updateRecommendationStatus(
        recommendationId: _currentRecommendation!.id,
        status: status,
      );
      _currentRecommendation = updated;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update recommendation status: $e';
      notifyListeners();
    }
  }

  /// Get the optimal charging time from current recommendation
  DateTime? get optimalChargingTime =>
      _currentRecommendation?.recommendedStartTime;

  /// Get the recommended end time
  DateTime? get recommendedEndTime =>
      _currentRecommendation?.recommendedEndTime;

  /// Get human-readable reasoning
  String? get reasoning => _currentRecommendation?.reasoning;

  /// Check if recommendation is valid (still in the future)
  bool get isRecommendationValid {
    if (_currentRecommendation == null) return false;
    final optimalTime = _currentRecommendation!.recommendedStartTime;
    return optimalTime.isAfter(DateTime.now());
  }

  /// Get the cheapest pricing in the loaded history
  PricingHistoryDto? get cheapestPrice {
    if (_pricingHistory.isEmpty) return null;

    return _pricingHistory.reduce((curr, next) =>
        curr.pricePerKwh < next.pricePerKwh ? curr : next);
  }

  /// Get the most expensive pricing in the loaded history
  PricingHistoryDto? get mostExpensivePrice {
    if (_pricingHistory.isEmpty) return null;

    return _pricingHistory.reduce((curr, next) =>
        curr.pricePerKwh > next.pricePerKwh ? curr : next);
  }

  /// Get average price from loaded history
  double get averagePrice {
    if (_pricingHistory.isEmpty) return 0.0;

    final total = _pricingHistory.fold<double>(
      0.0,
      (sum, price) => sum + price.pricePerKwh,
    );
    return total / _pricingHistory.length;
  }

  /// Get pricing for a specific hour
  PricingHistoryDto? getPricingForHour(DateTime hour) {
    final targetHour = DateTime(hour.year, hour.month, hour.day, hour.hour);

    for (final pricing in _pricingHistory) {
      final pricingHour = DateTime(
        pricing.timestamp.year,
        pricing.timestamp.month,
        pricing.timestamp.day,
        pricing.timestamp.hour,
      );

      if (pricingHour == targetHour) {
        return pricing;
      }
    }

    return null;
  }

  /// Check if pricing data needs refresh (older than 1 hour)
  bool get needsPricingRefresh {
    if (_lastPricingUpdate == null) return true;
    final difference = DateTime.now().difference(_lastPricingUpdate!);
    return difference.inHours >= 1;
  }

  /// Check if recommendation needs refresh (older than 30 minutes or invalid)
  bool get needsRecommendationRefresh {
    if (_lastRecommendationUpdate == null) return true;
    if (!isRecommendationValid) return true;
    final difference = DateTime.now().difference(_lastRecommendationUpdate!);
    return difference.inMinutes >= 30;
  }

  /// Refresh all data (pricing and recommendation)
  Future<void> refreshAll({
    required String vehicleId,
    DateTime? requiredBy,
    double? energyNeeded,
  }) async {
    await Future.wait([
      loadTodayTomorrowPricing(),
      generateRecommendation(
        vehicleId: vehicleId,
        requiredBy: requiredBy,
        energyNeeded: energyNeeded,
      ),
    ]);
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _pricingHistory = [];
    _currentRecommendation = null;
    _lastPricingUpdate = null;
    _lastRecommendationUpdate = null;
    _error = null;
    notifyListeners();
  }
}
