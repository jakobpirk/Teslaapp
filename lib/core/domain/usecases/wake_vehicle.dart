import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to wake up the vehicle
class WakeVehicle extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  WakeVehicle(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.wakeVehicle();
  }
}
