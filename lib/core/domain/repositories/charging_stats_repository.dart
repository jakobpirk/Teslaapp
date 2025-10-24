import 'package:dartz/dartz.dart';
import '../entities/charging_session_entity.dart';
import '../failures/failure.dart';

abstract class ChargingStatsRepository {
  /// Get all charging sessions for a specific vehicle
  Future<Either<Failure, List<ChargingSessionEntity>>> getChargingSessions(
      String vehicleId);

  /// Get charging sessions within a date range
  Future<Either<Failure, List<ChargingSessionEntity>>>
      getChargingSessionsByDateRange(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get a specific charging session by ID
  Future<Either<Failure, ChargingSessionEntity>> getChargingSession(
      String sessionId);

  /// Save a new charging session
  Future<Either<Failure, void>> saveChargingSession(
    String vehicleId,
    ChargingSessionEntity session,
  );

  /// Update an existing charging session
  Future<Either<Failure, void>> updateChargingSession(
      ChargingSessionEntity session);

  /// Delete a charging session
  Future<Either<Failure, void>> deleteChargingSession(String sessionId);

  /// Get the most recent charging session
  Future<Either<Failure, ChargingSessionEntity?>> getMostRecentSession(
      String vehicleId);
}
