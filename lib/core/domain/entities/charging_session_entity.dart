class ChargingSessionEntity {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double startBatteryLevel;
  final double? endBatteryLevel;
  final double energyAdded; // kWh
  final double? peakChargingRate; // kW
  final List<ChargingDataPointEntity> dataPoints;
  final PricingDataEntity? pricing;
  final bool isComplete;

  ChargingSessionEntity({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startBatteryLevel,
    this.endBatteryLevel,
    required this.energyAdded,
    this.peakChargingRate,
    required this.dataPoints,
    this.pricing,
    required this.isComplete,
  });

  double get durationHours {
    if (endTime == null) {
      return DateTime.now().difference(startTime).inMinutes / 60.0;
    }
    return endTime!.difference(startTime).inMinutes / 60.0;
  }

  double get averageChargingRate {
    if (durationHours == 0) return 0;
    return energyAdded / durationHours;
  }

  double? get totalCost => pricing?.totalCost;

  double? get costPerKwh => pricing?.pricePerKwh;

  ChargingSessionEntity copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? startBatteryLevel,
    double? endBatteryLevel,
    double? energyAdded,
    double? peakChargingRate,
    List<ChargingDataPointEntity>? dataPoints,
    PricingDataEntity? pricing,
    bool? isComplete,
  }) {
    return ChargingSessionEntity(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startBatteryLevel: startBatteryLevel ?? this.startBatteryLevel,
      endBatteryLevel: endBatteryLevel ?? this.endBatteryLevel,
      energyAdded: energyAdded ?? this.energyAdded,
      peakChargingRate: peakChargingRate ?? this.peakChargingRate,
      dataPoints: dataPoints ?? this.dataPoints,
      pricing: pricing ?? this.pricing,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class ChargingDataPointEntity {
  final DateTime timestamp;
  final double batteryLevel; // percentage 0-100
  final double? chargeRate; // kW
  final double? voltage;
  final double? current;
  final bool isCharging;

  ChargingDataPointEntity({
    required this.timestamp,
    required this.batteryLevel,
    this.chargeRate,
    this.voltage,
    this.current,
    required this.isCharging,
  });

  ChargingDataPointEntity copyWith({
    DateTime? timestamp,
    double? batteryLevel,
    double? chargeRate,
    double? voltage,
    double? current,
    bool? isCharging,
  }) {
    return ChargingDataPointEntity(
      timestamp: timestamp ?? this.timestamp,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      chargeRate: chargeRate ?? this.chargeRate,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      isCharging: isCharging ?? this.isCharging,
    );
  }
}

class PricingDataEntity {
  final double pricePerKwh; // price per kilowatt-hour
  final double totalCost;
  final String currency;
  final List<HourlyPriceEntity> hourlyPrices;

  PricingDataEntity({
    required this.pricePerKwh,
    required this.totalCost,
    required this.currency,
    required this.hourlyPrices,
  });

  PricingDataEntity copyWith({
    double? pricePerKwh,
    double? totalCost,
    String? currency,
    List<HourlyPriceEntity>? hourlyPrices,
  }) {
    return PricingDataEntity(
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      hourlyPrices: hourlyPrices ?? this.hourlyPrices,
    );
  }
}

class HourlyPriceEntity {
  final DateTime hour;
  final double pricePerKwh;
  final double energyUsed; // kWh consumed in this hour

  HourlyPriceEntity({
    required this.hour,
    required this.pricePerKwh,
    required this.energyUsed,
  });

  double get cost => pricePerKwh * energyUsed;

  HourlyPriceEntity copyWith({
    DateTime? hour,
    double? pricePerKwh,
    double? energyUsed,
  }) {
    return HourlyPriceEntity(
      hour: hour ?? this.hour,
      pricePerKwh: pricePerKwh ?? this.pricePerKwh,
      energyUsed: energyUsed ?? this.energyUsed,
    );
  }
}
