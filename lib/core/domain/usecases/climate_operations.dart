import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to start climate control
class StartClimate extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  StartClimate(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.startClimate();
  }
}

/// Use case to stop climate control
class StopClimate extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  StopClimate(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.stopClimate();
  }
}

/// Parameters for setting temperature
class TemperatureParams {
  final double temperature;

  const TemperatureParams(this.temperature);
}

/// Use case to set climate temperature
class SetTemperature extends UseCase<void, TemperatureParams> {
  final VehicleRepository repository;

  SetTemperature(this.repository);

  @override
  Future<Either<Failure, void>> call(TemperatureParams params) {
    return repository.setTemperature(params.temperature);
  }
}

/// Use case to enable max defrost
class EnableMaxDefrost extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  EnableMaxDefrost(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.enableMaxDefrost();
  }
}

/// Use case to disable max defrost
class DisableMaxDefrost extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  DisableMaxDefrost(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.disableMaxDefrost();
  }
}

/// Parameters for seat heater/cooler
class SeatControlParams {
  final int seat;
  final int level;

  const SeatControlParams(this.seat, this.level);
}

/// Use case to set seat heater
class SetSeatHeater extends UseCase<void, SeatControlParams> {
  final VehicleRepository repository;

  SetSeatHeater(this.repository);

  @override
  Future<Either<Failure, void>> call(SeatControlParams params) {
    return repository.setSeatHeater(params.seat, params.level);
  }
}

/// Use case to set seat cooler
class SetSeatCooler extends UseCase<void, SeatControlParams> {
  final VehicleRepository repository;

  SetSeatCooler(this.repository);

  @override
  Future<Either<Failure, void>> call(SeatControlParams params) {
    return repository.setSeatCooler(params.seat, params.level);
  }
}

/// Use case to enable steering wheel heater
class EnableSteeringWheelHeater extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  EnableSteeringWheelHeater(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.enableSteeringWheelHeater();
  }
}

/// Use case to disable steering wheel heater
class DisableSteeringWheelHeater extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  DisableSteeringWheelHeater(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.disableSteeringWheelHeater();
  }
}
