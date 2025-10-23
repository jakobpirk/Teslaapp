import 'package:dartz/dartz.dart';
import '../entities/vehicle_entity.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to get current vehicle state
class GetVehicleState extends NoParamsUseCase<VehicleEntity> {
  final VehicleRepository repository;

  GetVehicleState(this.repository);

  @override
  Future<Either<Failure, VehicleEntity>> call() {
    return repository.getVehicleState();
  }
}
