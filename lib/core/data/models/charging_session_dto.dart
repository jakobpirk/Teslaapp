import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingSessionDto {
  final String id;
  final Timestamp startTime;
  final Timestamp? endTime;
  final double startBatteryLevel;
  final double? endBatteryLevel;
  final double energyAdded;
  final double? peakChargingRate;
  final List<ChargingDataPointDto> dataPoints;
  final PricingDataDto? pricing;
  final String location;
  final bool isComplete;

  ChargingSessionDto({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startBatteryLevel,
    this.endBatteryLevel,
    required this.energyAdded,
    this.peakChargingRate,
    required this.dataPoints,
    this.pricing,
    required this.location,
    required this.isComplete,
  });

  factory ChargingSessionDto.fromFirestore(Map<String, dynamic> data, String id) {
    return ChargingSessionDto(
      id: id,
      startTime: data['startTime'] as Timestamp,
      endTime: data['endTime'] as Timestamp?,
      startBatteryLevel: (data['startBatteryLevel'] as num).toDouble(),
      endBatteryLevel: (data['endBatteryLevel'] as num?)?.toDouble(),
      energyAdded: (data['energyAdded'] as num).toDouble(),
      peakChargingRate: (data['peakChargingRate'] as num?)?.toDouble(),
      dataPoints: (data['dataPoints'] as List<dynamic>?)
              ?.map((e) => ChargingDataPointDto.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      pricing: data['pricing'] != null
          ? PricingDataDto.fromMap(data['pricing'] as Map<String, dynamic>)
          : null,
      location: data['location'] as String? ?? 'Unknown',
      isComplete: data['isComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'startBatteryLevel': startBatteryLevel,
      'endBatteryLevel': endBatteryLevel,
      'energyAdded': energyAdded,
      'peakChargingRate': peakChargingRate,
      'dataPoints': dataPoints.map((e) => e.toMap()).toList(),
      'pricing': pricing?.toMap(),
      'location': location,
      'isComplete': isComplete,
    };
  }
}

class ChargingDataPointDto {
  final Timestamp timestamp;
  final double batteryLevel;
  final double? chargeRate;
  final double? voltage;
  final double? current;
  final bool isCharging;

  ChargingDataPointDto({
    required this.timestamp,
    required this.batteryLevel,
    this.chargeRate,
    this.voltage,
    this.current,
    required this.isCharging,
  });

  factory ChargingDataPointDto.fromMap(Map<String, dynamic> data) {
    return ChargingDataPointDto(
      timestamp: data['timestamp'] as Timestamp,
      batteryLevel: (data['batteryLevel'] as num).toDouble(),
      chargeRate: (data['chargeRate'] as num?)?.toDouble(),
      voltage: (data['voltage'] as num?)?.toDouble(),
      current: (data['current'] as num?)?.toDouble(),
      isCharging: data['isCharging'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'batteryLevel': batteryLevel,
      'chargeRate': chargeRate,
      'voltage': voltage,
      'current': current,
      'isCharging': isCharging,
    };
  }
}

class PricingDataDto {
  final double pricePerKwh;
  final double totalCost;
  final String currency;
  final List<HourlyPriceDto> hourlyPrices;

  PricingDataDto({
    required this.pricePerKwh,
    required this.totalCost,
    required this.currency,
    required this.hourlyPrices,
  });

  factory PricingDataDto.fromMap(Map<String, dynamic> data) {
    return PricingDataDto(
      pricePerKwh: (data['pricePerKwh'] as num).toDouble(),
      totalCost: (data['totalCost'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      hourlyPrices: (data['hourlyPrices'] as List<dynamic>?)
              ?.map((e) => HourlyPriceDto.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pricePerKwh': pricePerKwh,
      'totalCost': totalCost,
      'currency': currency,
      'hourlyPrices': hourlyPrices.map((e) => e.toMap()).toList(),
    };
  }
}

class HourlyPriceDto {
  final Timestamp hour;
  final double pricePerKwh;
  final double energyUsed;

  HourlyPriceDto({
    required this.hour,
    required this.pricePerKwh,
    required this.energyUsed,
  });

  factory HourlyPriceDto.fromMap(Map<String, dynamic> data) {
    return HourlyPriceDto(
      hour: data['hour'] as Timestamp,
      pricePerKwh: (data['pricePerKwh'] as num).toDouble(),
      energyUsed: (data['energyUsed'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'pricePerKwh': pricePerKwh,
      'energyUsed': energyUsed,
    };
  }
}
