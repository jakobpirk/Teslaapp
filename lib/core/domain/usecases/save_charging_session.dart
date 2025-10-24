import 'package:dartz/dartz.dart';
import '../entities/charging_session_entity.dart';
import '../failures/failure.dart';
import '../repositories/charging_stats_repository.dart';

class SaveChargingSession {
  final ChargingStatsRepository repository;

  SaveChargingSession(this.repository);

  Future<Either<Failure, void>> call(
    String vehicleId,
    ChargingSessionEntity session,
  ) async {
    return await repository.saveChargingSession(vehicleId, session);
  }
}
