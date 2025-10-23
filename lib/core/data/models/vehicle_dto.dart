/// Data Transfer Object for vehicle state from API
/// This represents the raw data structure from the Tessie API
class VehicleDto {
  final String? displayName;
  final String? state;
  final double? batteryLevel;
  final double? batteryRange;
  final Map<String, dynamic>? chargeState;
  final Map<String, dynamic>? vehicleState;
  final Map<String, dynamic>? climateState;
  final Map<String, dynamic>? driveState;
  final String? lastSeen;

  VehicleDto({
    this.displayName,
    this.state,
    this.batteryLevel,
    this.batteryRange,
    this.chargeState,
    this.vehicleState,
    this.climateState,
    this.driveState,
    this.lastSeen,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      displayName: json['display_name'],
      state: json['state'],
      batteryLevel: json['battery_level']?.toDouble(),
      batteryRange: json['battery_range']?.toDouble(),
      chargeState: json['charge_state'],
      vehicleState: json['vehicle_state'],
      climateState: json['climate_state'],
      driveState: json['drive_state'],
      lastSeen: json['last_seen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'state': state,
      'battery_level': batteryLevel,
      'battery_range': batteryRange,
      'charge_state': chargeState,
      'vehicle_state': vehicleState,
      'climate_state': climateState,
      'drive_state': driveState,
      'last_seen': lastSeen,
    };
  }
}
