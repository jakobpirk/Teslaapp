import 'package:dartz/dartz.dart';
import '../entities/face_auth_response_entity.dart';
import '../failures/failure.dart';
import '../repositories/face_auth_repository.dart';
import 'usecase.dart';

/// Parameters for face authentication
class AuthenticateWithFaceParams {
  final String userId;
  final String? reason;

  const AuthenticateWithFaceParams({
    required this.userId,
    this.reason,
  });
}

/// Use case to authenticate user with face biometric
/// This handles the complete authentication flow including:
/// - Checking if biometric is available
/// - Triggering face recognition
/// - Validating the authentication result
/// - Creating secure session
class AuthenticateWithFace
    extends UseCase<FaceAuthResponseEntity, AuthenticateWithFaceParams> {
  final FaceAuthRepository repository;

  AuthenticateWithFace(this.repository);

  @override
  Future<Either<Failure, FaceAuthResponseEntity>> call(
    AuthenticateWithFaceParams params,
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

        // Check if face is enrolled
        final enrolledResult = await repository.isFaceEnrolled(params.userId);

        return enrolledResult.fold(
          (failure) => Left(failure),
          (isEnrolled) async {
            if (!isEnrolled) {
              return const Left(
                FaceNotEnrolledException(
                  'Face biometric is not enrolled for this user',
                ),
              );
            }

            // Proceed with authentication
            return repository.authenticateWithFace(
              userId: params.userId,
              reason: params.reason,
            );
          },
        );
      },
    );
  }
}
