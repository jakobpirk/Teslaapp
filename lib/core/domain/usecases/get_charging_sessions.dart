import 'package:dartz/dartz.dart';
import '../entities/charging_session_entity.dart';
import '../failures/failure.dart';
import '../repositories/charging_stats_repository.dart';

class GetChargingSessions {
  final ChargingStatsRepository repository;

  GetChargingSessions(this.repository);

  Future<Either<Failure, List<ChargingSessionEntity>>> call(
      String vehicleId) async {
    return await repository.getChargingSessions(vehicleId);
  }
}
