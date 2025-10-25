import 'package:json_annotation/json_annotation.dart';

part 'vehicle_model_dto.g.dart';

/// Data Transfer Object for vehicle records from the backend database
/// This represents a user's registered vehicle (not real-time state)
@JsonSerializable()
class VehicleModelDto {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? vin;
  final String? model;
  final String? color;
  final int? year;
  @JsonKey(name: 'battery_capacity')
  final double? batteryCapacity;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'vehicle_config')
  final Map<String, dynamic>? vehicleConfig;
  @JsonKey(name: 'charge_limit')
  final int? chargeLimit;
  @JsonKey(name: 'auto_charging_enabled')
  final bool? autoChargingEnabled;
  @JsonKey(name: 'low_battery_protection_enabled')
  final bool? lowBatteryProtectionEnabled;
  @JsonKey(name: 'low_battery_threshold')
  final int? lowBatteryThreshold;
  @JsonKey(name: 'low_battery_stop_limit')
  final int? lowBatteryStopLimit;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  VehicleModelDto({
    required this.id,
    required this.userId,
    required this.displayName,
    this.vin,
    this.model,
    this.color,
    this.year,
    this.batteryCapacity,
    this.isActive = true,
    this.vehicleConfig,
    this.chargeLimit,
    this.autoChargingEnabled,
    this.lowBatteryProtectionEnabled,
    this.lowBatteryThreshold,
    this.lowBatteryStopLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModelDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleModelDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleModelDtoToJson(this);

  String get displayInfo {
    if (model != null && year != null) {
      return '$year $model - $displayName';
    }
    return displayName;
  }
}

@JsonSerializable()
class CreateVehicleDto {
  @JsonKey(name: 'tessie_vehicle_id')
  final String tessieVehicleId;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? vin;
  final String? model;
  final String? color;
  final int? year;
  @JsonKey(name: 'battery_capacity')
  final double? batteryCapacity;
  @JsonKey(name: 'vehicle_config')
  final Map<String, dynamic>? vehicleConfig;

  CreateVehicleDto({
    required this.tessieVehicleId,
    required this.displayName,
    this.vin,
    this.model,
    this.color,
    this.year,
    this.batteryCapacity,
    this.vehicleConfig,
  });

  factory CreateVehicleDto.fromJson(Map<String, dynamic> json) =>
      _$CreateVehicleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateVehicleDtoToJson(this);
}

@JsonSerializable()
class UpdateVehicleDto {
  @JsonKey(name: 'display_name')
  final String? displayName;
  final String? vin;
  final String? model;
  final String? color;
  final int? year;
  @JsonKey(name: 'battery_capacity')
  final double? batteryCapacity;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'vehicle_config')
  final Map<String, dynamic>? vehicleConfig;
  @JsonKey(name: 'charge_limit')
  final int? chargeLimit;
  @JsonKey(name: 'auto_charging_enabled')
  final bool? autoChargingEnabled;
  @JsonKey(name: 'low_battery_protection_enabled')
  final bool? lowBatteryProtectionEnabled;
  @JsonKey(name: 'low_battery_threshold')
  final int? lowBatteryThreshold;
  @JsonKey(name: 'low_battery_stop_limit')
  final int? lowBatteryStopLimit;

  UpdateVehicleDto({
    this.displayName,
    this.vin,
    this.model,
    this.color,
    this.year,
    this.batteryCapacity,
    this.isActive,
    this.vehicleConfig,
    this.chargeLimit,
    this.autoChargingEnabled,
    this.lowBatteryProtectionEnabled,
    this.lowBatteryThreshold,
    this.lowBatteryStopLimit,
  });

  factory UpdateVehicleDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateVehicleDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (displayName != null) json['display_name'] = displayName;
    if (vin != null) json['vin'] = vin;
    if (model != null) json['model'] = model;
    if (color != null) json['color'] = color;
    if (year != null) json['year'] = year;
    if (batteryCapacity != null) json['battery_capacity'] = batteryCapacity;
    if (isActive != null) json['is_active'] = isActive;
    if (vehicleConfig != null) json['vehicle_config'] = vehicleConfig;
    if (chargeLimit != null) json['charge_limit'] = chargeLimit;
    if (autoChargingEnabled != null) json['auto_charging_enabled'] = autoChargingEnabled;
    if (lowBatteryProtectionEnabled != null) json['low_battery_protection_enabled'] = lowBatteryProtectionEnabled;
    if (lowBatteryThreshold != null) json['low_battery_threshold'] = lowBatteryThreshold;
    if (lowBatteryStopLimit != null) json['low_battery_stop_limit'] = lowBatteryStopLimit;
    return json;
  }
}

@JsonSerializable()
class VehicleChargingSettingsDto {
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'charge_limit')
  final int chargeLimit;
  @JsonKey(name: 'auto_charging_enabled')
  final bool autoChargingEnabled;
  @JsonKey(name: 'low_battery_protection_enabled')
  final bool lowBatteryProtectionEnabled;
  @JsonKey(name: 'low_battery_threshold')
  final int lowBatteryThreshold;
  @JsonKey(name: 'low_battery_stop_limit')
  final int lowBatteryStopLimit;

  VehicleChargingSettingsDto({
    required this.vehicleId,
    required this.displayName,
    required this.chargeLimit,
    required this.autoChargingEnabled,
    required this.lowBatteryProtectionEnabled,
    required this.lowBatteryThreshold,
    required this.lowBatteryStopLimit,
  });

  factory VehicleChargingSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleChargingSettingsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleChargingSettingsDtoToJson(this);
}

@JsonSerializable()
class UpdateVehicleChargingSettingsDto {
  @JsonKey(name: 'charge_limit')
  final int? chargeLimit;
  @JsonKey(name: 'auto_charging_enabled')
  final bool? autoChargingEnabled;
  @JsonKey(name: 'low_battery_protection_enabled')
  final bool? lowBatteryProtectionEnabled;
  @JsonKey(name: 'low_battery_threshold')
  final int? lowBatteryThreshold;
  @JsonKey(name: 'low_battery_stop_limit')
  final int? lowBatteryStopLimit;

  UpdateVehicleChargingSettingsDto({
    this.chargeLimit,
    this.autoChargingEnabled,
    this.lowBatteryProtectionEnabled,
    this.lowBatteryThreshold,
    this.lowBatteryStopLimit,
  });

  factory UpdateVehicleChargingSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateVehicleChargingSettingsDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (chargeLimit != null) json['charge_limit'] = chargeLimit;
    if (autoChargingEnabled != null) json['auto_charging_enabled'] = autoChargingEnabled;
    if (lowBatteryProtectionEnabled != null) json['low_battery_protection_enabled'] = lowBatteryProtectionEnabled;
    if (lowBatteryThreshold != null) json['low_battery_threshold'] = lowBatteryThreshold;
    if (lowBatteryStopLimit != null) json['low_battery_stop_limit'] = lowBatteryStopLimit;
    return json;
  }
}
