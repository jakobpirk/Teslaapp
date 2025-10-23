import 'package:dartz/dartz.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_data_source.dart';
import '../mappers/vehicle_mapper.dart';

/// Implementation of the vehicle repository
/// This class handles data operations and error handling
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, VehicleEntity>> getVehicleState() async {
    try {
      final dto = await remoteDataSource.getVehicleState();
      final entity = VehicleMapper.toEntity(dto);
      return Right(entity);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> wakeVehicle() async {
    try {
      await remoteDataSource.wakeVehicle();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> lockVehicle() async {
    try {
      await remoteDataSource.lockVehicle();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> unlockVehicle() async {
    try {
      await remoteDataSource.unlockVehicle();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> flashLights() async {
    try {
      await remoteDataSource.flashLights();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> honkHorn() async {
    try {
      await remoteDataSource.honkHorn();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> startClimate() async {
    try {
      await remoteDataSource.startClimate();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> stopClimate() async {
    try {
      await remoteDataSource.stopClimate();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setTemperature(double temperature) async {
    try {
      await remoteDataSource.setTemperature(temperature);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> enableMaxDefrost() async {
    try {
      await remoteDataSource.enableMaxDefrost();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> disableMaxDefrost() async {
    try {
      await remoteDataSource.disableMaxDefrost();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setSeatHeater(int seat, int level) async {
    try {
      await remoteDataSource.setSeatHeater(seat, level);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setSeatCooler(int seat, int level) async {
    try {
      await remoteDataSource.setSeatCooler(seat, level);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> enableSteeringWheelHeater() async {
    try {
      await remoteDataSource.enableSteeringWheelHeater();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> disableSteeringWheelHeater() async {
    try {
      await remoteDataSource.disableSteeringWheelHeater();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> startCharging() async {
    try {
      await remoteDataSource.startCharging();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> stopCharging() async {
    try {
      await remoteDataSource.stopCharging();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setChargeLimit(int limit) async {
    try {
      await remoteDataSource.setChargeLimit(limit);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> enableSentryMode() async {
    try {
      await remoteDataSource.enableSentryMode();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> disableSentryMode() async {
    try {
      await remoteDataSource.disableSentryMode();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> openFrunk() async {
    try {
      await remoteDataSource.openFrunk();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> openTrunk() async {
    try {
      await remoteDataSource.openTrunk();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> ventWindows() async {
    try {
      await remoteDataSource.ventWindows();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> closeWindows() async {
    try {
      await remoteDataSource.closeWindows();
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  /// Handle exceptions and convert to domain failures
  Failure _handleException(Exception exception) {
    final message = exception.toString();

    if (message.contains('Failed to load vehicle state')) {
      return ServerFailure(message);
    } else if (message.contains('Request failed')) {
      return ServerFailure(message);
    } else if (message.contains('SocketException') ||
        message.contains('NetworkException')) {
      return NetworkFailure('Network error occurred');
    } else if (message.contains('401') || message.contains('403')) {
      return AuthenticationFailure('Authentication failed');
    } else {
      return UnknownFailure(message);
    }
  }
}
