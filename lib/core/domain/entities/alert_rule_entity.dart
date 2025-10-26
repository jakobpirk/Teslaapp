/// Domain entity representing an alert rule
class AlertRuleEntity {
  final String id;
  final String userId;
  final String? vehicleId;
  final String name;
  final String? description;
  final String ruleType;
  final Map<String, dynamic> conditions;
  final List<String> notificationChannels;
  final String? notificationTitle;
  final String? notificationMessage;
  final bool isEnabled;
  final int cooldownMinutes;
  final int priority;
  final DateTime? lastTriggeredAt;
  final int triggerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlertRuleEntity({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.name,
    this.description,
    required this.ruleType,
    required this.conditions,
    required this.notificationChannels,
    this.notificationTitle,
    this.notificationMessage,
    required this.isEnabled,
    required this.cooldownMinutes,
    required this.priority,
    this.lastTriggeredAt,
    required this.triggerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  String get priorityString {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  String get ruleTypeDisplay {
    switch (ruleType) {
      case 'not_plugged_in':
        return 'Not Plugged In';
      case 'battery_low':
        return 'Battery Low';
      case 'charge_complete':
        return 'Charge Complete';
      case 'left_unlocked':
        return 'Left Unlocked';
      case 'sentry_triggered':
        return 'Sentry Triggered';
      case 'climate_on':
        return 'Climate On';
      case 'unusual_energy_consumption':
        return 'Unusual Energy';
      case 'software_update_available':
        return 'Software Update';
      default:
        return 'Custom';
    }
  }

  AlertRuleEntity copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? name,
    String? description,
    String? ruleType,
    Map<String, dynamic>? conditions,
    List<String>? notificationChannels,
    String? notificationTitle,
    String? notificationMessage,
    bool? isEnabled,
    int? cooldownMinutes,
    int? priority,
    DateTime? lastTriggeredAt,
    int? triggerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertRuleEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      description: description ?? this.description,
      ruleType: ruleType ?? this.ruleType,
      conditions: conditions ?? this.conditions,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      isEnabled: isEnabled ?? this.isEnabled,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      priority: priority ?? this.priority,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      triggerCount: triggerCount ?? this.triggerCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
