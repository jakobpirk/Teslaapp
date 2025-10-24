import 'package:dartz/dartz.dart';
import '../entities/face_enrollment_entity.dart';
import '../failures/failure.dart';
import '../repositories/face_auth_repository.dart';
import 'usecase.dart';

/// Parameters for face biometric enrollment
class EnrollFaceBiometricParams {
  final String userId;
  final String? deviceId;

  const EnrollFaceBiometricParams({
    required this.userId,
    this.deviceId,
  });
}

/// Use case to enroll face biometric for a user
/// This handles the complete enrollment flow including:
/// - Checking if biometric is available on device
/// - Verifying if already enrolled (optional re-enrollment)
/// - Capturing face data
/// - Storing face template securely
/// - Creating enrollment record
class EnrollFaceBiometric
    extends UseCase<FaceEnrollmentEntity, EnrollFaceBiometricParams> {
  final FaceAuthRepository repository;

  EnrollFaceBiometric(this.repository);

  @override
  Future<Either<Failure, FaceEnrollmentEntity>> call(
    EnrollFaceBiometricParams params,
  ) async {
    // First check if biometric is available
    final availableResult = await repository.isBiometricAvailable();

    return availableResult.fold(
      (failure) => Left(failure),
      (isAvailable) async {
        if (!isAvailable) {
          return const Left(
            BiometricNotAvailableFailure(
              'Face biometric is not available on this device',
            ),
          );
        }

        // Check if already enrolled
        final enrolledResult = await repository.isFaceEnrolled(params.userId);

        return enrolledResult.fold(
          (failure) => Left(failure),
          (isEnrolled) async {
            // If already enrolled, we can either delete and re-enroll
            // or just update the existing enrollment
            // For now, we'll allow re-enrollment by proceeding

            // Proceed with enrollment
            return repository.enrollFaceBiometric(
              userId: params.userId,
              deviceId: params.deviceId,
            );
          },
        );
      },
    );
  }
}
