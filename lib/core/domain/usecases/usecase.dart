import 'package:dartz/dartz.dart';
import '../failures/failure.dart';

/// Base class for all use cases
/// Params: Parameters required for the use case
/// Type: Return type of the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// No parameters class
class NoParams {
  const NoParams();
}
