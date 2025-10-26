import 'package:dartz/dartz.dart';
import '../entities/co2_statistics_entity.dart';
import '../failures/failure.dart';

/// Repository interface for CO2 statistics operations
abstract class CO2StatisticsRepository {
  /// Get CO2 statistics for the user
  Future<Either<Failure, CO2StatisticsEntity>> getUserStatistics({
    String? startDate,
    String? endDate,
  });

  /// Get CO2 statistics for a specific vehicle
  Future<Either<Failure, CO2StatisticsEntity>> getVehicleStatistics(
    String vehicleId, {
    String? startDate,
    String? endDate,
  });

  /// Get CO2 saving tips
  Future<Either<Failure, List<CO2SavingTip>>> getSavingTips();

  /// Get dashboard data with all statistics
  Future<Either<Failure, Map<String, dynamic>>> getDashboardData();
}
