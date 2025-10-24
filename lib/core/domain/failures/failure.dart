/// Base class for all domain failures
abstract class Failure {
  final String message;

  const Failure(this.message);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

/// Vehicle-specific failures
class VehicleFailure extends Failure {
  const VehicleFailure(super.message);
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

/// Face recognition specific failures
class FaceRecognitionFailure extends Failure {
  const FaceRecognitionFailure(super.message);
}

/// Face enrollment failures
class FaceEnrollmentFailure extends Failure {
  const FaceEnrollmentFailure(super.message);
}

/// Face not found/enrolled
class FaceNotEnrolledException extends Failure {
  const FaceNotEnrolledException(super.message);
}

/// Face matching/verification failed
class FaceVerificationFailure extends Failure {
  const FaceVerificationFailure(super.message);
}

/// Biometric authentication failures
class BiometricAuthenticationFailure extends Failure {
  const BiometricAuthenticationFailure(super.message);
}

/// Biometric not available on device
class BiometricNotAvailableFailure extends Failure {
  const BiometricNotAvailableFailure(super.message);
}
