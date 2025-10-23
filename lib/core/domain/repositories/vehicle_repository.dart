import 'package:dartz/dartz.dart';
import '../entities/vehicle_entity.dart';
import '../failures/failure.dart';

/// Abstract repository interface for vehicle operations
/// This defines the contract that data layer must implement
abstract class VehicleRepository {
  /// Get current vehicle state
  Future<Either<Failure, VehicleEntity>> getVehicleState();

  /// Wake up the vehicle
  Future<Either<Failure, void>> wakeVehicle();

  /// Lock the vehicle
  Future<Either<Failure, void>> lockVehicle();

  /// Unlock the vehicle
  Future<Either<Failure, void>> unlockVehicle();

  /// Flash the vehicle lights
  Future<Either<Failure, void>> flashLights();

  /// Honk the vehicle horn
  Future<Either<Failure, void>> honkHorn();

  /// Start climate control
  Future<Either<Failure, void>> startClimate();

  /// Stop climate control
  Future<Either<Failure, void>> stopClimate();

  /// Set climate temperature
  Future<Either<Failure, void>> setTemperature(double temperature);

  /// Enable max defrost
  Future<Either<Failure, void>> enableMaxDefrost();

  /// Disable max defrost
  Future<Either<Failure, void>> disableMaxDefrost();

  /// Set seat heater level (0-3)
  Future<Either<Failure, void>> setSeatHeater(int seat, int level);

  /// Set seat cooler level (0-3)
  Future<Either<Failure, void>> setSeatCooler(int seat, int level);

  /// Enable steering wheel heater
  Future<Either<Failure, void>> enableSteeringWheelHeater();

  /// Disable steering wheel heater
  Future<Either<Failure, void>> disableSteeringWheelHeater();

  /// Start charging
  Future<Either<Failure, void>> startCharging();

  /// Stop charging
  Future<Either<Failure, void>> stopCharging();

  /// Set charge limit (50-100%)
  Future<Either<Failure, void>> setChargeLimit(int limit);

  /// Enable sentry mode
  Future<Either<Failure, void>> enableSentryMode();

  /// Disable sentry mode
  Future<Either<Failure, void>> disableSentryMode();

  /// Open frunk (front trunk)
  Future<Either<Failure, void>> openFrunk();

  /// Open trunk
  Future<Either<Failure, void>> openTrunk();

  /// Vent windows
  Future<Either<Failure, void>> ventWindows();

  /// Close windows
  Future<Either<Failure, void>> closeWindows();
}
