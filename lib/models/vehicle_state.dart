class VehicleState {
  final String displayName;
  final String state;
  final double? batteryLevel;
  final double? batteryRange;
  final bool isCharging;
  final String? chargingState;
  final int? chargeRate;
  final bool isLocked;
  final bool isClimateOn;
  final double? insideTemp;
  final double? outsideTemp;
  final double? targetTemp;
  final bool isSentryMode;
  final double? odometer;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? lastUpdated;

  VehicleState({
    required this.displayName,
    required this.state,
    this.batteryLevel,
    this.batteryRange,
    this.isCharging = false,
    this.chargingState,
    this.chargeRate,
    this.isLocked = true,
    this.isClimateOn = false,
    this.insideTemp,
    this.outsideTemp,
    this.targetTemp,
    this.isSentryMode = false,
    this.odometer,
    this.latitude,
    this.longitude,
    this.address,
    this.lastUpdated,
  });

  factory VehicleState.fromJson(Map<String, dynamic> json) {
    return VehicleState(
      displayName: json['display_name'] ?? 'Tesla',
      state: json['state'] ?? 'unknown',
      batteryLevel: json['battery_level']?.toDouble(),
      batteryRange: json['battery_range']?.toDouble(),
      isCharging: json['charge_state']?['charging_state'] == 'Charging',
      chargingState: json['charge_state']?['charging_state'],
      chargeRate: json['charge_state']?['charge_rate'],
      isLocked: json['vehicle_state']?['locked'] ?? true,
      isClimateOn: json['climate_state']?['is_climate_on'] ?? false,
      insideTemp: json['climate_state']?['inside_temp']?.toDouble(),
      outsideTemp: json['climate_state']?['outside_temp']?.toDouble(),
      targetTemp: json['climate_state']?['driver_temp_setting']?.toDouble(),
      isSentryMode: json['vehicle_state']?['sentry_mode'] ?? false,
      odometer: json['vehicle_state']?['odometer']?.toDouble(),
      latitude: json['drive_state']?['latitude']?.toDouble(),
      longitude: json['drive_state']?['longitude']?.toDouble(),
      address: json['drive_state']?['address'],
      lastUpdated: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : DateTime.now(),
    );
  }

  bool get isAsleep => state == 'asleep';
  bool get isOnline => state == 'online';

  String get batteryLevelString => batteryLevel != null
      ? '${batteryLevel!.toInt()}%'
      : 'N/A';

  String get rangeString => batteryRange != null
      ? '${batteryRange!.toInt()} mi'
      : 'N/A';
}
