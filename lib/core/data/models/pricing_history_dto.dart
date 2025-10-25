class PricingHistoryDto {
  final String id;
  final DateTime timestamp;
  final double pricePerKwh;
  final String currency;
  final String? utilityProvider;
  final String? rateType;
  final Map<String, dynamic>? metadata;

  PricingHistoryDto({
    required this.id,
    required this.timestamp,
    required this.pricePerKwh,
    required this.currency,
    this.utilityProvider,
    this.rateType,
    this.metadata,
  });

  factory PricingHistoryDto.fromJson(Map<String, dynamic> json) {
    return PricingHistoryDto(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      pricePerKwh: (json['price_per_kwh'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      utilityProvider: json['utility_provider'] as String?,
      rateType: json['rate_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'price_per_kwh': pricePerKwh,
      'currency': currency,
      'utility_provider': utilityProvider,
      'rate_type': rateType,
      'metadata': metadata,
    };
  }
}

class PricingHistoryListResponseDto {
  final List<PricingHistoryDto> data;
  final PricingMetaDto? meta;

  PricingHistoryListResponseDto({
    required this.data,
    this.meta,
  });

  factory PricingHistoryListResponseDto.fromJson(Map<String, dynamic> json) {
    return PricingHistoryListResponseDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => PricingHistoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] != null
          ? PricingMetaDto.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PricingMetaDto {
  final String startTime;
  final String endTime;
  final int count;
  final double? averagePrice;
  final double? minPrice;
  final double? maxPrice;

  PricingMetaDto({
    required this.startTime,
    required this.endTime,
    required this.count,
    this.averagePrice,
    this.minPrice,
    this.maxPrice,
  });

  factory PricingMetaDto.fromJson(Map<String, dynamic> json) {
    return PricingMetaDto(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      count: json['count'] as int,
      averagePrice: (json['average_price'] as num?)?.toDouble(),
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
    );
  }
}
