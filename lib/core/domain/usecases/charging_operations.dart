import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to start charging
class StartCharging extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  StartCharging(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.startCharging();
  }
}

/// Use case to stop charging
class StopCharging extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  StopCharging(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.stopCharging();
  }
}

/// Parameters for setting charge limit
class ChargeLimitParams {
  final int limit;

  const ChargeLimitParams(this.limit);
}

/// Use case to set charge limit
class SetChargeLimit extends UseCase<void, ChargeLimitParams> {
  final VehicleRepository repository;

  SetChargeLimit(this.repository);

  @override
  Future<Either<Failure, void>> call(ChargeLimitParams params) {
    return repository.setChargeLimit(params.limit);
  }
}
