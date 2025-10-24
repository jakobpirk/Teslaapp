import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tessie_app/core/domain/entities/face_auth_response_entity.dart';
import 'package:tessie_app/core/domain/failures/failure.dart';
import 'package:tessie_app/core/domain/repositories/face_auth_repository.dart';
import 'package:tessie_app/core/domain/usecases/authenticate_with_face.dart';

// Generate mocks
@GenerateMocks([FaceAuthRepository])
import 'authenticate_with_face_test.mocks.dart';

void main() {
  late AuthenticateWithFace useCase;
  late MockFaceAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockFaceAuthRepository();
    useCase = AuthenticateWithFace(mockRepository);
  });

  final testUserId = 'user123';
  final testAuthResponse = FaceAuthResponseEntity(
    isAuthenticated: true,
    userId: testUserId,
    sessionToken: 'token456',
    authenticatedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 24)),
    confidenceScore: 0.95,
    enrollmentId: 'enroll789',
    method: AuthenticationMethodEntity.faceBiometric,
  );

  group('AuthenticateWithFace', () {
    test('should return FaceAuthResponseEntity when authentication successful',
        () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: anyNamed('reason'),
      )).thenAnswer((_) async => Right(testAuthResponse));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, Right(testAuthResponse));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verify(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: null,
      )).called(1);
    });

    test('should pass custom reason to repository', () async {
      // Arrange
      const customReason = 'Custom authentication reason';
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: customReason,
      )).thenAnswer((_) async => Right(testAuthResponse));

      // Act
      final result = await useCase(
        const AuthenticateWithFaceParams(
          userId: testUserId,
          reason: customReason,
        ),
      );

      // Assert
      expect(result, Right(testAuthResponse));
      verify(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: customReason,
      )).called(1);
    });

    test('should return BiometricNotAvailableFailure when biometric unavailable',
        () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(false));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<BiometricNotAvailableFailure>()),
        (_) => fail('Should return failure'),
      );
      verify(mockRepository.isBiometricAvailable()).called(1);
      verifyNever(mockRepository.isFaceEnrolled(any));
      verifyNever(mockRepository.authenticateWithFace(
        userId: anyNamed('userId'),
        reason: anyNamed('reason'),
      ));
    });

    test(
        'should return BiometricNotAvailableFailure when checking availability fails',
        () async {
      // Arrange
      const failure = BiometricNotAvailableFailure('Check failed');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verifyNever(mockRepository.isFaceEnrolled(any));
    });

    test('should return FaceNotEnrolledException when face not enrolled',
        () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(false));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<FaceNotEnrolledException>()),
        (_) => fail('Should return failure'),
      );
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verifyNever(mockRepository.authenticateWithFace(
        userId: anyNamed('userId'),
        reason: anyNamed('reason'),
      ));
    });

    test('should return FaceNotEnrolledException when enrollment check fails',
        () async {
      // Arrange
      const failure = FaceNotEnrolledException('Check failed');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verifyNever(mockRepository.authenticateWithFace(
        userId: anyNamed('userId'),
        reason: anyNamed('reason'),
      ));
    });

    test('should return failure when authentication fails', () async {
      // Arrange
      const failure = BiometricAuthenticationFailure('Auth failed');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: anyNamed('reason'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verify(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: null,
      )).called(1);
    });

    test('should handle network failure during authentication', () async {
      // Arrange
      const failure = NetworkFailure('Network error');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: anyNamed('reason'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        AuthenticateWithFaceParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.authenticateWithFace(
        userId: testUserId,
        reason: null,
      )).called(1);
    });
  });
}
