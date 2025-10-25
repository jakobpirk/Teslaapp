import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/charging_session_entity.dart';
import '../models/charging_session_dto.dart';

class ChargingSessionMapper {
  static ChargingSessionEntity toEntity(ChargingSessionDto dto) {
    return ChargingSessionEntity(
      id: dto.id,
      startTime: dto.startTime.toDate(),
      endTime: dto.endTime?.toDate(),
      startBatteryLevel: dto.startBatteryLevel,
      endBatteryLevel: dto.endBatteryLevel,
      energyAdded: dto.energyAdded,
      peakChargingRate: dto.peakChargingRate,
      dataPoints: dto.dataPoints
          .map((dp) => ChargingDataPointMapper.toEntity(dp))
          .toList(),
      pricing: dto.pricing != null
          ? PricingDataMapper.toEntity(dto.pricing!)
          : null,
      isComplete: dto.isComplete,
    );
  }

  static ChargingSessionDto toDto(ChargingSessionEntity entity) {
    return ChargingSessionDto(
      id: entity.id,
      startTime: Timestamp.fromDate(entity.startTime),
      endTime:
          entity.endTime != null ? Timestamp.fromDate(entity.endTime!) : null,
      startBatteryLevel: entity.startBatteryLevel,
      endBatteryLevel: entity.endBatteryLevel,
      energyAdded: entity.energyAdded,
      peakChargingRate: entity.peakChargingRate,
      dataPoints: entity.dataPoints
          .map((dp) => ChargingDataPointMapper.toDto(dp))
          .toList(),
      pricing: entity.pricing != null
          ? PricingDataMapper.toDto(entity.pricing!)
          : null,
      isComplete: entity.isComplete,
    );
  }
}

class ChargingDataPointMapper {
  static ChargingDataPointEntity toEntity(ChargingDataPointDto dto) {
    return ChargingDataPointEntity(
      timestamp: dto.timestamp.toDate(),
      batteryLevel: dto.batteryLevel,
      chargeRate: dto.chargeRate,
      voltage: dto.voltage,
      current: dto.current,
      isCharging: dto.isCharging,
    );
  }

  static ChargingDataPointDto toDto(ChargingDataPointEntity entity) {
    return ChargingDataPointDto(
      timestamp: Timestamp.fromDate(entity.timestamp),
      batteryLevel: entity.batteryLevel,
      chargeRate: entity.chargeRate,
      voltage: entity.voltage,
      current: entity.current,
      isCharging: entity.isCharging,
    );
  }
}

class PricingDataMapper {
  static PricingDataEntity toEntity(PricingDataDto dto) {
    return PricingDataEntity(
      pricePerKwh: dto.pricePerKwh,
      totalCost: dto.totalCost,
      currency: dto.currency,
      hourlyPrices: dto.hourlyPrices
          .map((hp) => HourlyPriceMapper.toEntity(hp))
          .toList(),
    );
  }

  static PricingDataDto toDto(PricingDataEntity entity) {
    return PricingDataDto(
      pricePerKwh: entity.pricePerKwh,
      totalCost: entity.totalCost,
      currency: entity.currency,
      hourlyPrices:
          entity.hourlyPrices.map((hp) => HourlyPriceMapper.toDto(hp)).toList(),
    );
  }
}

class HourlyPriceMapper {
  static HourlyPriceEntity toEntity(HourlyPriceDto dto) {
    return HourlyPriceEntity(
      hour: dto.hour.toDate(),
      pricePerKwh: dto.pricePerKwh,
      energyUsed: dto.energyUsed,
    );
  }

  static HourlyPriceDto toDto(HourlyPriceEntity entity) {
    return HourlyPriceDto(
      hour: Timestamp.fromDate(entity.hour),
      pricePerKwh: entity.pricePerKwh,
      energyUsed: entity.energyUsed,
    );
  }
}
