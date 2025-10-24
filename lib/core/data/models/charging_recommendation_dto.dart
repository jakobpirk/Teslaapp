class ChargingRecommendationDto {
  final String id;
  final String vehicleId;
  final DateTime recommendedStartTime;
  final DateTime? recommendedEndTime;
  final double? estimatedCost;
  final double? costSavings;
  final int confidenceScore;
  final bool shouldChargeNow;
  final Map<String, dynamic>? factorScores;
  final String? reasoning;
  final String status;
  final DateTime? executedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChargingRecommendationDto({
    required this.id,
    required this.vehicleId,
    required this.recommendedStartTime,
    this.recommendedEndTime,
    this.estimatedCost,
    this.costSavings,
    required this.confidenceScore,
    required this.shouldChargeNow,
    this.factorScores,
    this.reasoning,
    required this.status,
    this.executedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChargingRecommendationDto.fromJson(Map<String, dynamic> json) {
    return ChargingRecommendationDto(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      recommendedStartTime: DateTime.parse(json['recommended_start_time'] as String),
      recommendedEndTime: json['recommended_end_time'] != null
          ? DateTime.parse(json['recommended_end_time'] as String)
          : null,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      costSavings: (json['cost_savings'] as num?)?.toDouble(),
      confidenceScore: json['confidence_score'] as int? ?? 0,
      shouldChargeNow: json['should_charge_now'] as bool? ?? false,
      factorScores: json['factor_scores'] as Map<String, dynamic>?,
      reasoning: json['reasoning'] as String?,
      status: json['status'] as String? ?? 'pending',
      executedAt: json['executed_at'] != null
          ? DateTime.parse(json['executed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'recommended_start_time': recommendedStartTime.toIso8601String(),
      'recommended_end_time': recommendedEndTime?.toIso8601String(),
      'estimated_cost': estimatedCost,
      'cost_savings': costSavings,
      'confidence_score': confidenceScore,
      'should_charge_now': shouldChargeNow,
      'factor_scores': factorScores,
      'reasoning': reasoning,
      'status': status,
      'executed_at': executedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChargingRecommendationResponseDto {
  final ChargingRecommendationDto recommendation;
  final bool? isValid;

  ChargingRecommendationResponseDto({
    required this.recommendation,
    this.isValid,
  });

  factory ChargingRecommendationResponseDto.fromJson(Map<String, dynamic> json) {
    // Check if the response has 'recommendation' key (for latest endpoint)
    // or is directly a recommendation object (for other endpoints)
    if (json.containsKey('recommendation')) {
      return ChargingRecommendationResponseDto(
        recommendation: ChargingRecommendationDto.fromJson(
          json['recommendation'] as Map<String, dynamic>,
        ),
        isValid: json['is_valid'] as bool?,
      );
    } else {
      return ChargingRecommendationResponseDto(
        recommendation: ChargingRecommendationDto.fromJson(json),
        isValid: null,
      );
    }
  }
}
