import 'package:dio/dio.dart';
import '../models/pricing_history_dto.dart';
import '../models/charging_recommendation_dto.dart';

/// HTTP datasource for smart charging features (pricing and recommendations)
class SmartChargingHttpDataSource {
  final Dio dio;
  final String baseUrl;

  SmartChargingHttpDataSource({
    required this.dio,
    required this.baseUrl,
  });

  /// Get pricing history for a date range
  Future<PricingHistoryListResponseDto> getPricingHistory({
    required DateTime startTime,
    required DateTime endTime,
    String location = 'default',
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/pricing',
        queryParameters: {
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'location': location,
        },
      );

      if (response.statusCode == 200) {
        return PricingHistoryListResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to get pricing history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get pricing history: $e');
    }
  }

  /// Get pricing for today and tomorrow
  Future<PricingHistoryListResponseDto> getTodayTomorrowPricing({
    String location = 'default',
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/pricing/today-tomorrow',
        queryParameters: {
          'location': location,
        },
      );

      if (response.statusCode == 200) {
        return PricingHistoryListResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to get today/tomorrow pricing: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get today/tomorrow pricing: $e');
    }
  }

  /// Get current pricing
  Future<PricingHistoryDto> getCurrentPricing({
    String location = 'default',
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/pricing/current',
        queryParameters: {
          'location': location,
        },
      );

      if (response.statusCode == 200) {
        return PricingHistoryDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else if (response.statusCode == 404) {
        throw Exception('No pricing data available');
      } else {
        throw Exception('Failed to get current pricing: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get current pricing: $e');
    }
  }

  /// Generate a new charging recommendation
  Future<ChargingRecommendationDto> generateRecommendation({
    required String vehicleId,
    String location = 'default',
    DateTime? requiredBy,
    double? energyNeeded,
  }) async {
    try {
      final data = <String, dynamic>{
        'location': location,
      };

      if (requiredBy != null) {
        data['required_by'] = requiredBy.toIso8601String();
      }

      if (energyNeeded != null) {
        data['energy_needed'] = energyNeeded;
      }

      final response = await dio.post(
        '$baseUrl/charging-recommendations/vehicle/$vehicleId/generate',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ChargingRecommendationDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to generate recommendation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate recommendation: $e');
    }
  }

  /// Get the latest recommendation for a vehicle
  Future<ChargingRecommendationResponseDto?> getLatestRecommendation(
    String vehicleId,
  ) async {
    try {
      final response = await dio.get(
        '$baseUrl/charging-recommendations/vehicle/$vehicleId/latest',
      );

      if (response.statusCode == 200) {
        return ChargingRecommendationResponseDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get latest recommendation: ${response.statusCode}');
      }
    } catch (e) {
      // Return null if no recommendations found instead of throwing
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get latest recommendation: $e');
    }
  }

  /// Get all recommendations for a vehicle
  Future<List<ChargingRecommendationDto>> getRecommendations(
    String vehicleId,
  ) async {
    try {
      final response = await dio.get(
        '$baseUrl/charging-recommendations/vehicle/$vehicleId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => ChargingRecommendationDto.fromJson(
                json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Mark a recommendation as executed
  Future<ChargingRecommendationDto> markRecommendationExecuted(
    String recommendationId,
  ) async {
    try {
      final response = await dio.post(
        '$baseUrl/charging-recommendations/$recommendationId/executed',
      );

      if (response.statusCode == 200) {
        return ChargingRecommendationDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to mark recommendation as executed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark recommendation as executed: $e');
    }
  }

  /// Update recommendation status
  Future<ChargingRecommendationDto> updateRecommendationStatus({
    required String recommendationId,
    required String status,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/charging-recommendations/$recommendationId/status',
        data: {
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        return ChargingRecommendationDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to update recommendation status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update recommendation status: $e');
    }
  }
}
