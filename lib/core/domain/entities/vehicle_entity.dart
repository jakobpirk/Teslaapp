/// Domain entity representing a vehicle's state
/// This is a pure business object with no dependencies on external frameworks
class VehicleEntity {
  final String displayName;
  final String state;
  final double batteryLevel;
  final double batteryRange;
  final bool isCharging;
  final String? chargingState;
  final double? chargeRate;
  final bool isClimateOn;
  final double? insideTemp;
  final double? outsideTemp;
  final double? targetTemp;
  final bool isLocked;
  final bool isSentryMode;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? odometer;
  final DateTime lastUpdated;

  const VehicleEntity({
    required this.displayName,
    required this.state,
    required this.batteryLevel,
    required this.batteryRange,
    required this.isCharging,
    this.chargingState,
    this.chargeRate,
    required this.isClimateOn,
    this.insideTemp,
    this.outsideTemp,
    this.targetTemp,
    required this.isLocked,
    required this.isSentryMode,
    this.latitude,
    this.longitude,
    this.address,
    this.odometer,
    required this.lastUpdated,
  });

  // Computed properties
  bool get isAsleep => state.toLowerCase() == 'asleep';
  bool get isOnline => state.toLowerCase() == 'online';

  String get batteryLevelString => '${batteryLevel.toStringAsFixed(0)}%';
  String get rangeString => '${batteryRange.toStringAsFixed(0)} km';

  VehicleEntity copyWith({
    String? displayName,
    String? state,
    double? batteryLevel,
    double? batteryRange,
    bool? isCharging,
    String? chargingState,
    double? chargeRate,
    bool? isClimateOn,
    double? insideTemp,
    double? outsideTemp,
    double? targetTemp,
    bool? isLocked,
    bool? isSentryMode,
    double? latitude,
    double? longitude,
    String? address,
    double? odometer,
    DateTime? lastUpdated,
  }) {
    return VehicleEntity(
      displayName: displayName ?? this.displayName,
      state: state ?? this.state,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryRange: batteryRange ?? this.batteryRange,
      isCharging: isCharging ?? this.isCharging,
      chargingState: chargingState ?? this.chargingState,
      chargeRate: chargeRate ?? this.chargeRate,
      isClimateOn: isClimateOn ?? this.isClimateOn,
      insideTemp: insideTemp ?? this.insideTemp,
      outsideTemp: outsideTemp ?? this.outsideTemp,
      targetTemp: targetTemp ?? this.targetTemp,
      isLocked: isLocked ?? this.isLocked,
      isSentryMode: isSentryMode ?? this.isSentryMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      odometer: odometer ?? this.odometer,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
