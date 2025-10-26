/// Domain entity representing CO2 statistics
class CO2StatisticsEntity {
  final CO2Summary summary;
  final CO2Savings savings;
  final Map<String, MonthlyData> monthlyBreakdown;
  final RenewableBreakdown renewableBreakdown;
  final CO2Comparison comparison;

  const CO2StatisticsEntity({
    required this.summary,
    required this.savings,
    required this.monthlyBreakdown,
    required this.renewableBreakdown,
    required this.comparison,
  });
}

class CO2Summary {
  final double totalCO2Emitted; // grams
  final double totalCO2Kg; // kilograms
  final double totalEnergyKwh;
  final double avgCO2PerKwh;
  final double avgRenewablePercentage;
  final int totalSessions;

  const CO2Summary({
    required this.totalCO2Emitted,
    required this.totalCO2Kg,
    required this.totalEnergyKwh,
    required this.avgCO2PerKwh,
    required this.avgRenewablePercentage,
    required this.totalSessions,
  });
}

class CO2Savings {
  final double co2SavedVsGridAverage; // grams
  final double co2SavedVsGridKg; // kg
  final double co2SavedVsIceCar; // grams
  final double co2SavedVsIceKg; // kg
  final double equivalentKmDriven;

  const CO2Savings({
    required this.co2SavedVsGridAverage,
    required this.co2SavedVsGridKg,
    required this.co2SavedVsIceCar,
    required this.co2SavedVsIceKg,
    required this.equivalentKmDriven,
  });
}

class MonthlyData {
  final double co2Emitted;
  final double co2Kg;
  final double energyKwh;
  final double avgCO2PerKwh;
  final int sessionCount;
  final double avgRenewablePercentage;

  const MonthlyData({
    required this.co2Emitted,
    required this.co2Kg,
    required this.energyKwh,
    required this.avgCO2PerKwh,
    required this.sessionCount,
    required this.avgRenewablePercentage,
  });
}

class RenewableBreakdown {
  final double renewableKwh;
  final double nonRenewableKwh;
  final double renewablePercentage;

  const RenewableBreakdown({
    required this.renewableKwh,
    required this.nonRenewableKwh,
    required this.renewablePercentage,
  });
}

class CO2Comparison {
  final double gridAverageIntensity;
  final double yourAverageIntensity;
  final double improvementPercentage;

  const CO2Comparison({
    required this.gridAverageIntensity,
    required this.yourAverageIntensity,
    required this.improvementPercentage,
  });
}

class CO2SavingTip {
  final String title;
  final String description;
  final String priority; // 'high', 'medium', 'low', 'info'

  const CO2SavingTip({
    required this.title,
    required this.description,
    required this.priority,
  });
}
