import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to lock the vehicle
class LockVehicle extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  LockVehicle(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.lockVehicle();
  }
}

/// Use case to unlock the vehicle
class UnlockVehicle extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  UnlockVehicle(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.unlockVehicle();
  }
}
