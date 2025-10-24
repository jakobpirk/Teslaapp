import 'package:dartz/dartz.dart';
import '../../domain/entities/face_auth_response_entity.dart';
import '../../domain/entities/face_enrollment_entity.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/face_auth_repository.dart';
import '../datasources/face_auth_local_data_source.dart';
import '../datasources/face_auth_remote_data_source.dart';
import '../mappers/face_auth_mapper.dart';
import '../exceptions/data_exceptions.dart';

/// Implementation of the face authentication repository
/// This class orchestrates between local and remote data sources
/// and handles error mapping to domain failures
class FaceAuthRepositoryImpl implements FaceAuthRepository {
  final FaceAuthLocalDataSource localDataSource;
  final FaceAuthRemoteDataSource remoteDataSource;

  FaceAuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, FaceAuthResponseEntity>> authenticateWithFace({
    required String userId,
    String? reason,
  }) async {
    try {
      // Step 1: Check if biometric is available
      final isAvailable = await localDataSource.isBiometricAvailable();
      if (!isAvailable) {
        return const Left(
          BiometricNotAvailableFailure('Biometric not available on device'),
        );
      }

      // Step 2: Check if face is enrolled locally
      final isEnrolled = await localDataSource.isFaceEnrolled(userId);
      if (!isEnrolled) {
        return const Left(
          FaceNotEnrolledException('Face not enrolled for this user'),
        );
      }

      // Step 3: Perform local biometric authentication
      final authReason = reason ?? 'Authenticate to access your account';
      final didAuthenticate = await localDataSource.authenticateLocally(
        authReason,
      );

      if (!didAuthenticate) {
        return const Left(
          BiometricAuthenticationFailure('Biometric authentication failed'),
        );
      }

      // Step 4: Get enrollment details
      final enrollmentDto = await localDataSource.getEnrollment(userId);
      if (enrollmentDto == null) {
        return const Left(
          FaceNotEnrolledException('Enrollment data not found'),
        );
      }

      // Step 5: Verify with remote server and create session
      final authResponseDto = await remoteDataSource.verifyAuthentication(
        userId: userId,
        enrollmentId: enrollmentDto.enrollmentId,
      );

      // Step 6: Store session token locally
      await localDataSource.storeSessionToken(
        userId,
        authResponseDto.sessionToken,
      );

      // Step 7: Convert DTO to Entity and return
      final authResponse = FaceAuthResponseMapper.toEntity(authResponseDto);
      return Right(authResponse);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FaceEnrollmentEntity>> enrollFaceBiometric({
    required String userId,
    String? deviceId,
  }) async {
    try {
      // Step 1: Check if biometric is available
      final isAvailable = await localDataSource.isBiometricAvailable();
      if (!isAvailable) {
        return const Left(
          BiometricNotAvailableFailure('Biometric not available on device'),
        );
      }

      // Step 2: Perform biometric authentication to enroll
      final didAuthenticate = await localDataSource.authenticateLocally(
        'Authenticate to enroll your biometric',
      );

      if (!didAuthenticate) {
        return const Left(
          BiometricAuthenticationFailure('Biometric authentication failed'),
        );
      }

      // Step 3: Register enrollment with remote server
      final enrollmentDto = await remoteDataSource.registerEnrollment(
        userId: userId,
        deviceId: deviceId,
      );

      // Step 4: Store enrollment data locally
      await localDataSource.storeEnrollment(enrollmentDto);

      // Step 5: Convert DTO to Entity and return
      final enrollment = FaceEnrollmentMapper.toEntity(enrollmentDto);
      return Right(enrollment);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFaceEnrolled(String userId) async {
    try {
      final isEnrolled = await localDataSource.isFaceEnrolled(userId);
      return Right(isEnrolled);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FaceEnrollmentEntity>> getFaceEnrollment(
    String userId,
  ) async {
    try {
      // Try to get from local storage first
      final localEnrollment = await localDataSource.getEnrollment(userId);
      if (localEnrollment != null) {
        final enrollment = FaceEnrollmentMapper.toEntity(localEnrollment);
        return Right(enrollment);
      }

      // If not found locally, try remote
      final remoteEnrollment = await remoteDataSource.getEnrollment(userId);
      final enrollment = FaceEnrollmentMapper.toEntity(remoteEnrollment);
      return Right(enrollment);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFaceEnrollment(String userId) async {
    try {
      // Delete from both local and remote
      await Future.wait([
        localDataSource.deleteEnrollment(userId),
        remoteDataSource.deleteEnrollment(userId),
        localDataSource.deleteSessionToken(userId),
      ]);

      return const Right(null);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isBiometricAvailable() async {
    try {
      final isAvailable = await localDataSource.isBiometricAvailable();
      return Right(isAvailable);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifySession(String sessionToken) async {
    try {
      final isValid = await remoteDataSource.verifySessionToken(sessionToken);
      return Right(isValid);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> invalidateSession(String sessionToken) async {
    try {
      await remoteDataSource.invalidateSession(sessionToken);
      return const Right(null);
    } on DataException catch (e) {
      return Left(_handleDataException(e));
    } on Exception catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Handle data exceptions and convert to domain failures
  Failure _handleDataException(DataException exception) {
    if (exception is BiometricException) {
      switch (exception.errorType) {
        case BiometricErrorType.notAvailable:
          return BiometricNotAvailableFailure(exception.message);
        case BiometricErrorType.notEnrolled:
          return FaceNotEnrolledException(exception.message);
        case BiometricErrorType.authenticationFailed:
        case BiometricErrorType.cancelled:
        case BiometricErrorType.lockout:
          return BiometricAuthenticationFailure(exception.message);
        case BiometricErrorType.hardwareError:
          return BiometricNotAvailableFailure(exception.message);
      }
    } else if (exception is DataNotFoundException) {
      return FaceNotEnrolledException(exception.message);
    } else if (exception is StorageException) {
      return UnknownFailure('Storage error: ${exception.message}');
    } else if (exception is FirestoreException) {
      if (exception.operation?.contains('enroll') == true) {
        return FaceEnrollmentFailure(exception.message);
      } else if (exception.operation?.contains('verify') == true ||
          exception.operation?.contains('authentication') == true) {
        return FaceVerificationFailure(exception.message);
      }
      return ServerFailure('Database error: ${exception.message}');
    } else if (exception is ParseException) {
      return UnknownFailure('Data parsing error: ${exception.message}');
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message);
    } else {
      return UnknownFailure(exception.message);
    }
  }
}
