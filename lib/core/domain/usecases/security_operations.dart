import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/vehicle_repository.dart';
import 'usecase.dart';

/// Use case to enable sentry mode
class EnableSentryMode extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  EnableSentryMode(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.enableSentryMode();
  }
}

/// Use case to disable sentry mode
class DisableSentryMode extends NoParamsUseCase<void> {
  final VehicleRepository repository;

  DisableSentryMode(this.repository);

  @override
  Future<Either<Failure, void>> call() {
    return repository.disableSentryMode();
  }
}
