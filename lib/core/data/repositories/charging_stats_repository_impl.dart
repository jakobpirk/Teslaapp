import 'package:dartz/dartz.dart';
import '../../domain/entities/charging_session_entity.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/charging_stats_repository.dart';
import '../datasources/charging_stats_http_datasource.dart';
import '../mappers/charging_session_mapper.dart';
import '../exceptions/data_exceptions.dart';

class ChargingStatsRepositoryImpl implements ChargingStatsRepository {
  final ChargingStatsHttpDataSource remoteDataSource;

  ChargingStatsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ChargingSessionEntity>>> getChargingSessions(
      String vehicleId) async {
    try {
      final sessions = await remoteDataSource.getChargingSessions(vehicleId);
      return Right(
          sessions.map((dto) => ChargingSessionMapper.toEntity(dto)).toList());
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChargingSessionEntity>>>
      getChargingSessionsByDateRange(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sessions = await remoteDataSource.getChargingSessionsByDateRange(
        vehicleId,
        startDate,
        endDate,
      );
      return Right(
          sessions.map((dto) => ChargingSessionMapper.toEntity(dto)).toList());
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChargingSessionEntity>> getChargingSession(
      String sessionId) async {
    try {
      final session = await remoteDataSource.getChargingSession(sessionId);
      return Right(ChargingSessionMapper.toEntity(session));
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveChargingSession(
    String vehicleId,
    ChargingSessionEntity session,
  ) async {
    try {
      final dto = ChargingSessionMapper.toDto(session);
      await remoteDataSource.saveChargingSession(vehicleId, dto);
      return const Right(null);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateChargingSession(
      ChargingSessionEntity session) async {
    try {
      final dto = ChargingSessionMapper.toDto(session);
      await remoteDataSource.updateChargingSession(dto);
      return const Right(null);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteChargingSession(String sessionId) async {
    try {
      await remoteDataSource.deleteChargingSession(sessionId);
      return const Right(null);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChargingSessionEntity?>> getMostRecentSession(
      String vehicleId) async {
    try {
      final session = await remoteDataSource.getMostRecentSession(vehicleId);
      if (session == null) {
        return const Right(null);
      }
      return Right(ChargingSessionMapper.toEntity(session));
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Handle data exceptions and convert to domain failures
  Failure _handleDataException(DataException exception) {
    if (exception is FirestoreException) {
      return ServerFailure('Database error: ${exception.message}');
    } else if (exception is DataNotFoundException) {
      return ServerFailure('Data not found: ${exception.message}');
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else {
      return UnknownFailure(exception.message);
    }
  }
}
