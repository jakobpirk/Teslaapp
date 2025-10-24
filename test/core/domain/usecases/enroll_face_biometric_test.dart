import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tessie_app/core/domain/entities/face_enrollment_entity.dart';
import 'package:tessie_app/core/domain/failures/failure.dart';
import 'package:tessie_app/core/domain/repositories/face_auth_repository.dart';
import 'package:tessie_app/core/domain/usecases/enroll_face_biometric.dart';

// Generate mocks
@GenerateMocks([FaceAuthRepository])
import 'enroll_face_biometric_test.mocks.dart';

void main() {
  late EnrollFaceBiometric useCase;
  late MockFaceAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockFaceAuthRepository();
    useCase = EnrollFaceBiometric(mockRepository);
  });

  final testUserId = 'user123';
  final testDeviceId = 'device789';
  final testEnrollment = FaceEnrollmentEntity(
    userId: testUserId,
    enrollmentId: 'enroll456',
    enrolledAt: DateTime.now(),
    isActive: true,
    deviceId: testDeviceId,
    biometricType: BiometricTypeEntity.face,
  );

  group('EnrollFaceBiometric', () {
    test('should return FaceEnrollmentEntity when enrollment successful',
        () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(false));
      when(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => Right(testEnrollment));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, Right(testEnrollment));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verify(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: null,
      )).called(1);
    });

    test('should pass device ID to repository when provided', () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(false));
      when(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: testDeviceId,
      )).thenAnswer((_) async => Right(testEnrollment));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(
          userId: testUserId,
          deviceId: testDeviceId,
        ),
      );

      // Assert
      expect(result, Right(testEnrollment));
      verify(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: testDeviceId,
      )).called(1);
    });

    test('should allow re-enrollment when already enrolled', () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(true)); // Already enrolled
      when(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => Right(testEnrollment));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, Right(testEnrollment));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verify(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: null,
      )).called(1);
    });

    test('should return BiometricNotAvailableFailure when biometric unavailable',
        () async {
      // Arrange
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(false));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure, isA<BiometricNotAvailableFailure>()),
        (_) => fail('Should return failure'),
      );
      verify(mockRepository.isBiometricAvailable()).called(1);
      verifyNever(mockRepository.isFaceEnrolled(any));
      verifyNever(mockRepository.enrollFaceBiometric(
        userId: anyNamed('userId'),
        deviceId: anyNamed('deviceId'),
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
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verifyNever(mockRepository.isFaceEnrolled(any));
      verifyNever(mockRepository.enrollFaceBiometric(
        userId: anyNamed('userId'),
        deviceId: anyNamed('deviceId'),
      ));
    });

    test('should return failure when enrollment check fails', () async {
      // Arrange
      const failure = FaceEnrollmentFailure('Check failed');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verifyNever(mockRepository.enrollFaceBiometric(
        userId: anyNamed('userId'),
        deviceId: anyNamed('deviceId'),
      ));
    });

    test('should return failure when enrollment fails', () async {
      // Arrange
      const failure = FaceEnrollmentFailure('Enrollment failed');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(false));
      when(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.isBiometricAvailable()).called(1);
      verify(mockRepository.isFaceEnrolled(testUserId)).called(1);
      verify(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: null,
      )).called(1);
    });

    test('should handle network failure during enrollment', () async {
      // Arrange
      const failure = NetworkFailure('Network error');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(false));
      when(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: null,
      )).called(1);
    });

    test('should handle server failure during enrollment', () async {
      // Arrange
      const failure = ServerFailure('Server error');
      when(mockRepository.isBiometricAvailable())
          .thenAnswer((_) async => const Right(true));
      when(mockRepository.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => const Right(false));
      when(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(
        EnrollFaceBiometricParams(userId: testUserId),
      );

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: null,
      )).called(1);
    });
  });
}
