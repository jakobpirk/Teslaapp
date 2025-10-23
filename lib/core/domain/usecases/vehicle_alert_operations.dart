import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to flash vehicle lights
class FlashLights extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  FlashLights(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.flashLights();
  }
}

/// Use case to honk vehicle horn
class HonkHorn extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  HonkHorn(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.honkHorn();
  }
}
