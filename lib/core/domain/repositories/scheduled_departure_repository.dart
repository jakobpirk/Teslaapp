import 'package:dartz/dartz.dart';
import '../entities/scheduled_departure_entity.dart';
import '../failures/failure.dart';

/// Repository interface for scheduled departure operations
abstract class ScheduledDepartureRepository {
  /// Get all scheduled departures for the user
  Future<Either<Failure, List<ScheduledDepartureEntity>>> getScheduledDepartures();

  /// Get scheduled departures for a specific vehicle
  Future<Either<Failure, List<ScheduledDepartureEntity>>> getVehicleSchedules(String vehicleId);

  /// Get a single scheduled departure
  Future<Either<Failure, ScheduledDepartureEntity>> getSchedule(String id);

  /// Create a new scheduled departure
  Future<Either<Failure, ScheduledDepartureEntity>> createSchedule(Map<String, dynamic> data);

  /// Update an existing scheduled departure
  Future<Either<Failure, ScheduledDepartureEntity>> updateSchedule(String id, Map<String, dynamic> data);

  /// Delete a scheduled departure
  Future<Either<Failure, void>> deleteSchedule(String id);

  /// Toggle enable/disable
  Future<Either<Failure, ScheduledDepartureEntity>> toggleSchedule(String id);
}
