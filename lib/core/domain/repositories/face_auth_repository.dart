import 'package:dartz/dartz.dart';
import '../entities/face_enrollment_entity.dart';
import '../entities/face_auth_response_entity.dart';
import '../failures/failure.dart';

/// Abstract repository interface for face authentication operations
/// This defines the contract that data layer must implement
abstract class FaceAuthRepository {
  /// Authenticate user using face biometric
  /// Returns authentication response with session token and confidence score
  Future<Either<Failure, FaceAuthResponseEntity>> authenticateWithFace({
    required String userId,
    String? reason,
  });

  /// Enroll a new face biometric for the user
  /// Returns enrollment entity with enrollment ID and metadata
  Future<Either<Failure, FaceEnrollmentEntity>> enrollFaceBiometric({
    required String userId,
    String? deviceId,
  });

  /// Check if face biometric is enrolled for the user
  Future<Either<Failure, bool>> isFaceEnrolled(String userId);

  /// Get face enrollment details for the user
  Future<Either<Failure, FaceEnrollmentEntity>> getFaceEnrollment(
    String userId,
  );

  /// Delete face enrollment for the user
  Future<Either<Failure, void>> deleteFaceEnrollment(String userId);

  /// Check if biometric authentication is available on the device
  Future<Either<Failure, bool>> isBiometricAvailable();

  /// Verify if the authentication session is still valid
  Future<Either<Failure, bool>> verifySession(String sessionToken);

  /// Invalidate/logout the authentication session
  Future<Either<Failure, void>> invalidateSession(String sessionToken);
}
