/// Domain entity representing a scheduled departure
class ScheduledDepartureEntity {
  final String id;
  final String vehicleId;
  final String userId;
  final String departureTime; // HH:mm format
  final List<int> daysOfWeek; // 0=Sun, 1=Mon, ..., 6=Sat
  final String timezone;
  final bool isEnabled;
  final bool preconditionClimate;
  final bool preconditionBattery;
  final double? targetTemperature;
  final int preconditioningMinutes;
  final bool chargeBeforeDeparture;
  final int? targetBatteryLevel;
  final bool offPeakOnly;
  final DateTime? lastExecutedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduledDepartureEntity({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.departureTime,
    required this.daysOfWeek,
    required this.timezone,
    required this.isEnabled,
    required this.preconditionClimate,
    required this.preconditionBattery,
    this.targetTemperature,
    required this.preconditioningMinutes,
    required this.chargeBeforeDeparture,
    this.targetBatteryLevel,
    required this.offPeakOnly,
    this.lastExecutedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get daysOfWeekString {
    if (daysOfWeek.length == 7) {
      return 'Every day';
    } else if (daysOfWeek.length == 5 && !daysOfWeek.contains(0) && !daysOfWeek.contains(6)) {
      return 'Weekdays';
    } else if (daysOfWeek.length == 2 && daysOfWeek.contains(0) && daysOfWeek.contains(6)) {
      return 'Weekends';
    } else {
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return daysOfWeek.map((d) => dayNames[d]).join(', ');
    }
  }

  ScheduledDepartureEntity copyWith({
    String? id,
    String? vehicleId,
    String? userId,
    String? departureTime,
    List<int>? daysOfWeek,
    String? timezone,
    bool? isEnabled,
    bool? preconditionClimate,
    bool? preconditionBattery,
    double? targetTemperature,
    int? preconditioningMinutes,
    bool? chargeBeforeDeparture,
    int? targetBatteryLevel,
    bool? offPeakOnly,
    DateTime? lastExecutedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduledDepartureEntity(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      departureTime: departureTime ?? this.departureTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timezone: timezone ?? this.timezone,
      isEnabled: isEnabled ?? this.isEnabled,
      preconditionClimate: preconditionClimate ?? this.preconditionClimate,
      preconditionBattery: preconditionBattery ?? this.preconditionBattery,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      preconditioningMinutes: preconditioningMinutes ?? this.preconditioningMinutes,
      chargeBeforeDeparture: chargeBeforeDeparture ?? this.chargeBeforeDeparture,
      targetBatteryLevel: targetBatteryLevel ?? this.targetBatteryLevel,
      offPeakOnly: offPeakOnly ?? this.offPeakOnly,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
