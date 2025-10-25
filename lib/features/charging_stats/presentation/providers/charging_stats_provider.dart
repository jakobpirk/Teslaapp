import 'package:flutter/foundation.dart';
import '../../../../core/domain/entities/charging_session_entity.dart';
import '../../../../core/domain/usecases/get_charging_sessions.dart';
import '../../../../core/domain/usecases/save_charging_session.dart';
import '../../../../utils/mock_pricing_generator.dart';

class ChargingStatsProvider with ChangeNotifier {
  final GetChargingSessions _getChargingSessions;
  final SaveChargingSession _saveChargingSession;

  List<ChargingSessionEntity> _sessions = [];
  bool _isLoading = false;
  String? _error;
  bool _useMockData = kIsWeb ? true : true; // Always use mock data on web, default to true on mobile

  ChargingStatsProvider({
    required GetChargingSessions getChargingSessions,
    required SaveChargingSession saveChargingSession,
  })  : _getChargingSessions = getChargingSessions,
        _saveChargingSession = saveChargingSession;

  List<ChargingSessionEntity> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useMockData => _useMockData;

  /// Get all charging sessions for a vehicle
  Future<void> loadChargingSessions(String vehicleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_useMockData) {
        // Generate mock data for demo purposes
        await Future.delayed(
            const Duration(milliseconds: 500)); // Simulate network delay
        _sessions = MockPricingGenerator.generateMockSessions(
          count: 15,
          daysBack: 30,
        );
        _error = null;
      } else {
        final result = await _getChargingSessions(vehicleId);
        result.fold(
          (failure) {
            _error = failure.message;
            _sessions = [];
          },
          (sessions) {
            _sessions = sessions;
            _error = null;
          },
        );
      }
    } catch (e) {
      _error = 'Failed to load charging sessions: $e';
      _sessions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a new charging session
  Future<void> saveSession(
      String vehicleId, ChargingSessionEntity session) async {
    if (_useMockData) {
      // In mock mode, just add to local list
      _sessions.insert(0, session);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _saveChargingSession(vehicleId, session);
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (_) {
          // Reload sessions after saving
          loadChargingSessions(vehicleId);
        },
      );
    } catch (e) {
      _error = 'Failed to save charging session: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle between mock data and real Firebase data
  /// On web, this is disabled and mock data is always used
  void toggleMockData() {
    if (kIsWeb) {
      return; // Cannot toggle on web - always use mock data
    }
    _useMockData = !_useMockData;
    notifyListeners();
  }

  /// Get sessions from last N days
  List<ChargingSessionEntity> getRecentSessions({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _sessions
        .where((session) => session.startTime.isAfter(cutoffDate))
        .toList();
  }

  /// Get total energy consumed in last N days
  double getTotalEnergyAdded({int days = 30}) {
    final recentSessions = getRecentSessions(days: days);
    return recentSessions.fold(
        0.0, (sum, session) => sum + session.energyAdded);
  }

  /// Get total cost in last N days
  double getTotalCost({int days = 30}) {
    final recentSessions = getRecentSessions(days: days);
    return recentSessions.fold(
        0.0, (sum, session) => sum + (session.totalCost ?? 0));
  }

  /// Get average cost per kWh
  double getAverageCostPerKwh({int days = 30}) {
    final recentSessions = getRecentSessions(days: days);
    if (recentSessions.isEmpty) return 0;

    final totalEnergy = getTotalEnergyAdded(days: days);
    final totalCost = getTotalCost(days: days);

    return totalEnergy > 0 ? totalCost / totalEnergy : 0;
  }

  /// Get charging session count
  int getSessionCount({int days = 30}) {
    return getRecentSessions(days: days).length;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
