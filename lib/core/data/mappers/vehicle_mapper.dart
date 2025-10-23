import '../../domain/entities/vehicle_entity.dart';
import '../models/vehicle_dto.dart';

/// Mapper to convert between DTO and Entity
class VehicleMapper {
  /// Convert DTO to Domain Entity
  static VehicleEntity toEntity(VehicleDto dto) {
    return VehicleEntity(
      displayName: dto.displayName ?? 'Tesla',
      state: dto.state ?? 'unknown',
      batteryLevel: dto.batteryLevel ?? 0.0,
      batteryRange: dto.batteryRange ?? 0.0,
      isCharging: dto.chargeState?['charging_state'] == 'Charging',
      chargingState: dto.chargeState?['charging_state'],
      chargeRate: dto.chargeState?['charge_rate']?.toDouble(),
      isClimateOn: dto.climateState?['is_climate_on'] ?? false,
      insideTemp: dto.climateState?['inside_temp']?.toDouble(),
      outsideTemp: dto.climateState?['outside_temp']?.toDouble(),
      targetTemp: dto.climateState?['driver_temp_setting']?.toDouble(),
      isLocked: dto.vehicleState?['locked'] ?? true,
      isSentryMode: dto.vehicleState?['sentry_mode'] ?? false,
      latitude: dto.driveState?['latitude']?.toDouble(),
      longitude: dto.driveState?['longitude']?.toDouble(),
      address: dto.driveState?['address'],
      odometer: dto.vehicleState?['odometer']?.toDouble(),
      lastUpdated: dto.lastSeen != null
          ? DateTime.parse(dto.lastSeen!)
          : DateTime.now(),
    );
  }

  /// Convert Entity to DTO (if needed for caching or other purposes)
  static VehicleDto toDto(VehicleEntity entity) {
    return VehicleDto(
      displayName: entity.displayName,
      state: entity.state,
      batteryLevel: entity.batteryLevel,
      batteryRange: entity.batteryRange,
      chargeState: {
        'charging_state': entity.chargingState,
        'charge_rate': entity.chargeRate,
      },
      vehicleState: {
        'locked': entity.isLocked,
        'sentry_mode': entity.isSentryMode,
        'odometer': entity.odometer,
      },
      climateState: {
        'is_climate_on': entity.isClimateOn,
        'inside_temp': entity.insideTemp,
        'outside_temp': entity.outsideTemp,
        'driver_temp_setting': entity.targetTemp,
      },
      driveState: {
        'latitude': entity.latitude,
        'longitude': entity.longitude,
        'address': entity.address,
      },
      lastSeen: entity.lastUpdated.toIso8601String(),
    );
  }
}
