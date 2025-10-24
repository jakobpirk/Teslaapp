import 'package:dartz/dartz.dart';
import '../../domain/entities/face_auth_response_entity.dart';
import '../../domain/entities/face_enrollment_entity.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/face_auth_repository.dart';
import '../datasources/face_auth_local_data_source.dart';
import '../datasources/face_auth_remote_data_source.dart';
import '../mappers/face_auth_mapper.dart';

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
    } on Exception catch (e) {
      return Left(_handleException(e));
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
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> isFaceEnrolled(String userId) async {
    try {
      final isEnrolled = await localDataSource.isFaceEnrolled(userId);
      return Right(isEnrolled);
    } on Exception catch (e) {
      return Left(_handleException(e));
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
    } on Exception catch (e) {
      return Left(_handleException(e));
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
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> isBiometricAvailable() async {
    try {
      final isAvailable = await localDataSource.isBiometricAvailable();
      return Right(isAvailable);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> verifySession(String sessionToken) async {
    try {
      final isValid = await remoteDataSource.verifySessionToken(sessionToken);
      return Right(isValid);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> invalidateSession(String sessionToken) async {
    try {
      await remoteDataSource.invalidateSession(sessionToken);
      return const Right(null);
    } on Exception catch (e) {
      return Left(_handleException(e));
    }
  }

  /// Handle exceptions and convert to domain failures
  Failure _handleException(Exception exception) {
    final message = exception.toString();

    if (message.contains('Biometric not available') ||
        message.contains('biometric availability')) {
      return BiometricNotAvailableFailure(message);
    } else if (message.contains('Face not enrolled') ||
        message.contains('No active enrollment')) {
      return FaceNotEnrolledException(message);
    } else if (message.contains('Biometric authentication failed') ||
        message.contains('authentication failed')) {
      return BiometricAuthenticationFailure(message);
    } else if (message.contains('enrollment failed') ||
        message.contains('register enrollment')) {
      return FaceEnrollmentFailure(message);
    } else if (message.contains('verification failed') ||
        message.contains('verify authentication')) {
      return FaceVerificationFailure(message);
    } else if (message.contains('SocketException') ||
        message.contains('NetworkException')) {
      return const NetworkFailure('Network error occurred');
    } else if (message.contains('401') || message.contains('403')) {
      return const AuthenticationFailure('Authentication failed');
    } else {
      return UnknownFailure(message);
    }
  }
}
