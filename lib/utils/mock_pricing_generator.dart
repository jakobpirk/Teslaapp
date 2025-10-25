import 'dart:math';
import '../core/domain/entities/charging_session_entity.dart';

class MockPricingGenerator {
  static final Random _random = Random();

  /// Generate mock pricing data for a charging session
  /// This simulates time-of-use pricing with peak/off-peak rates
  static PricingDataEntity generatePricingForSession(
    DateTime startTime,
    DateTime endTime,
    double energyAdded,
  ) {
    final hourlyPrices = <HourlyPriceEntity>[];
    var currentTime = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
    );

    final sessionEnd = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      endTime.hour,
    );

    // Distribute energy across hours
    final totalHours =
        sessionEnd.difference(currentTime).inHours.toDouble() + 1;
    final energyPerHour = energyAdded / totalHours;

    double totalCost = 0;
    double totalEnergy = 0;

    while (currentTime.isBefore(sessionEnd) ||
        currentTime.isAtSameMomentAs(sessionEnd)) {
      final pricePerKwh = _getPriceForHour(currentTime);
      final energyThisHour = energyPerHour;

      hourlyPrices.add(HourlyPriceEntity(
        hour: currentTime,
        pricePerKwh: pricePerKwh,
        energyUsed: energyThisHour,
      ));

      totalCost += pricePerKwh * energyThisHour;
      totalEnergy += energyThisHour;
      currentTime = currentTime.add(const Duration(hours: 1));
    }

    final avgPricePerKwh = totalEnergy > 0 ? (totalCost / totalEnergy).toDouble() : 0.0;

    return PricingDataEntity(
      pricePerKwh: avgPricePerKwh,
      totalCost: totalCost,
      currency: 'USD',
      hourlyPrices: hourlyPrices,
    );
  }

  /// Get price per kWh for a specific hour
  /// Simulates time-of-use pricing:
  /// - Off-peak (11pm - 7am): $0.08 - $0.12/kWh
  /// - Mid-peak (7am - 4pm, 9pm - 11pm): $0.15 - $0.20/kWh
  /// - Peak (4pm - 9pm): $0.25 - $0.35/kWh
  static double _getPriceForHour(DateTime time) {
    final hour = time.hour;

    if (hour >= 23 || hour < 7) {
      // Off-peak: 11pm - 7am
      return 0.08 + _random.nextDouble() * 0.04; // $0.08 - $0.12
    } else if (hour >= 16 && hour < 21) {
      // Peak: 4pm - 9pm
      return 0.25 + _random.nextDouble() * 0.10; // $0.25 - $0.35
    } else {
      // Mid-peak: 7am - 4pm, 9pm - 11pm
      return 0.15 + _random.nextDouble() * 0.05; // $0.15 - $0.20
    }
  }

  /// Generate mock charging session with data points
  static ChargingSessionEntity generateMockSession({
    required String id,
    required DateTime startTime,
    int durationMinutes = 180, // 3 hours default
    double startBatteryLevel = 20.0,
    double endBatteryLevel = 80.0,
  }) {
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    final dataPoints = <ChargingDataPointEntity>[];

    // Generate data points every 15 minutes
    var currentTime = startTime;
    final batteryIncrease = endBatteryLevel - startBatteryLevel;
    final totalIntervals = durationMinutes ~/ 15;

    for (int i = 0; i <= totalIntervals; i++) {
      final progress = i / totalIntervals;
      final currentBatteryLevel =
          startBatteryLevel + (batteryIncrease * progress);

      // Simulate decreasing charge rate as battery fills up
      double chargeRate;
      if (currentBatteryLevel < 50) {
        chargeRate = 45 + _random.nextDouble() * 5; // 45-50 kW
      } else if (currentBatteryLevel < 80) {
        chargeRate = 30 + _random.nextDouble() * 10; // 30-40 kW
      } else {
        chargeRate = 15 + _random.nextDouble() * 10; // 15-25 kW
      }

      dataPoints.add(ChargingDataPointEntity(
        timestamp: currentTime,
        batteryLevel: currentBatteryLevel,
        chargeRate: chargeRate,
        voltage: 400 + _random.nextDouble() * 20, // 400-420V
        current: chargeRate * 1000 / 410, // I = P / V
        isCharging: i < totalIntervals,
      ));

      currentTime = currentTime.add(const Duration(minutes: 15));
    }

    // Calculate energy added (kWh)
    // Rough estimate: average charge rate * duration in hours
    final avgChargeRate = dataPoints
            .where((dp) => dp.isCharging)
            .map((dp) => dp.chargeRate ?? 0)
            .reduce((a, b) => a + b) /
        dataPoints.where((dp) => dp.isCharging).length;
    final energyAdded = avgChargeRate * (durationMinutes / 60.0);

    final pricing = generatePricingForSession(
      startTime,
      endTime,
      energyAdded,
    );

    return ChargingSessionEntity(
      id: id,
      startTime: startTime,
      endTime: endTime,
      startBatteryLevel: startBatteryLevel,
      endBatteryLevel: endBatteryLevel,
      energyAdded: energyAdded,
      peakChargingRate: dataPoints
          .map((dp) => dp.chargeRate ?? 0)
          .reduce((a, b) => a > b ? a : b),
      dataPoints: dataPoints,
      pricing: pricing,
      isComplete: true,
    );
  }

  static String _randomLocation() {
    final locations = [
      'Home',
      'Supercharger - Downtown',
      'Supercharger - Highway Rest Stop',
      'Office Parking',
      'Shopping Mall',
      'Hotel',
    ];
    return locations[_random.nextInt(locations.length)];
  }

  /// Generate multiple mock charging sessions for testing
  static List<ChargingSessionEntity> generateMockSessions({
    int count = 10,
    int daysBack = 30,
  }) {
    final sessions = <ChargingSessionEntity>[];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final daysAgo = _random.nextInt(daysBack);
      final hour = _random.nextInt(24);
      final startTime = DateTime(
        now.year,
        now.month,
        now.day - daysAgo,
        hour,
        _random.nextInt(60),
      );

      sessions.add(generateMockSession(
        id: 'mock_session_$i',
        startTime: startTime,
        durationMinutes: 120 + _random.nextInt(180), // 2-5 hours
        startBatteryLevel: 15.0 + _random.nextDouble() * 30, // 15-45%
        endBatteryLevel: 75.0 + _random.nextDouble() * 20, // 75-95%
      ));
    }

    // Sort by start time, most recent first
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return sessions;
  }
}
