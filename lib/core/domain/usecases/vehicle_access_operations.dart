import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to open frunk
class OpenFrunk extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  OpenFrunk(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.openFrunk();
  }
}

/// Use case to open trunk
class OpenTrunk extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  OpenTrunk(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.openTrunk();
  }
}

/// Use case to vent windows
class VentWindows extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  VentWindows(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.ventWindows();
  }
}

/// Use case to close windows
class CloseWindows extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  CloseWindows(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.closeWindows();
  }
}
