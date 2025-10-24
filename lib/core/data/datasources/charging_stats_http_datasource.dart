import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/charging_session_dto.dart';

/// HTTP-based implementation of ChargingStatsRemoteDataSource
/// This replaces Firebase Firestore with REST API calls
class ChargingStatsHttpDataSource {
  final Dio dio;
  final String baseUrl;
  static const String _endpoint = '/api/v1/charging-sessions';

  ChargingStatsHttpDataSource({
    required this.dio,
    required this.baseUrl,
  });

  /// Get all charging sessions for a specific vehicle
  Future<List<ChargingSessionDto>> getChargingSessions(String vehicleId) async {
    try {
      final response = await dio.get(
        '$baseUrl$_endpoint/vehicle/$vehicleId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception('Failed to get charging sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get charging sessions: $e');
    }
  }

  /// Get charging sessions within a date range
  Future<List<ChargingSessionDto>> getChargingSessionsByDateRange(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await dio.get(
        '$baseUrl$_endpoint/vehicle/$vehicleId/date-range',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => _fromJson(json)).toList();
      } else {
        throw Exception('Failed to get charging sessions by date range: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get charging sessions by date range: $e');
    }
  }

  /// Get a specific charging session by ID
  Future<ChargingSessionDto> getChargingSession(String sessionId) async {
    try {
      final response = await dio.get('$baseUrl$_endpoint/$sessionId');

      if (response.statusCode == 200) {
        return _fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Charging session not found: $sessionId');
      } else {
        throw Exception('Failed to get charging session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get charging session: $e');
    }
  }

  /// Save a new charging session
  Future<void> saveChargingSession(
    String vehicleId,
    ChargingSessionDto session,
  ) async {
    try {
      final response = await dio.post(
        '$baseUrl$_endpoint',
        data: _toJson(session, vehicleId),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to save charging session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save charging session: $e');
    }
  }

  /// Update an existing charging session
  Future<void> updateChargingSession(ChargingSessionDto session) async {
    try {
      final response = await dio.put(
        '$baseUrl$_endpoint/${session.id}',
        data: _toJson(session, null),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update charging session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update charging session: $e');
    }
  }

  /// Delete a charging session
  Future<void> deleteChargingSession(String sessionId) async {
    try {
      final response = await dio.delete('$baseUrl$_endpoint/$sessionId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete charging session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete charging session: $e');
    }
  }

  /// Get the most recent charging session
  Future<ChargingSessionDto?> getMostRecentSession(String vehicleId) async {
    try {
      final response = await dio.get(
        '$baseUrl$_endpoint/vehicle/$vehicleId/recent',
      );

      if (response.statusCode == 200) {
        return _fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get most recent session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get most recent session: $e');
    }
  }

  /// Convert API JSON to DTO
  ChargingSessionDto _fromJson(Map<String, dynamic> json) {
    return ChargingSessionDto(
      id: json['id'] as String,
      startTime: Timestamp.fromDate(DateTime.parse(json['start_time'] as String)),
      endTime: json['end_time'] != null
          ? Timestamp.fromDate(DateTime.parse(json['end_time'] as String))
          : null,
      startBatteryLevel: (json['start_battery_level'] as num?)?.toDouble() ?? 0.0,
      endBatteryLevel: (json['end_battery_level'] as num?)?.toDouble(),
      energyAdded: (json['energy_added'] as num).toDouble(),
      peakChargingRate: (json['charge_rate'] as num?)?.toDouble(),
      dataPoints: [], // These would need to be stored separately in a real implementation
      pricing: json['cost'] != null
          ? PricingDataDto(
              pricePerKwh: 0.0,
              totalCost: (json['cost'] as num).toDouble(),
              currency: 'USD',
              hourlyPrices: [],
            )
          : null,
      location: json['location'] as String? ?? 'Unknown',
      isComplete: json['end_time'] != null,
    );
  }

  /// Convert DTO to API JSON
  Map<String, dynamic> _toJson(ChargingSessionDto session, String? vehicleId) {
    final data = {
      'start_time': session.startTime.toDate().toIso8601String(),
      'end_time': session.endTime?.toDate().toIso8601String(),
      'start_battery_level': session.startBatteryLevel.toInt(),
      'end_battery_level': session.endBatteryLevel?.toInt(),
      'energy_added': session.energyAdded,
      'charge_rate': session.peakChargingRate,
      'cost': session.pricing?.totalCost ?? 0.0,
      'location': session.location,
    };

    if (vehicleId != null) {
      data['vehicle_id'] = vehicleId;
    }

    return data;
  }
}
