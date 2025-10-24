import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tessie_app/core/data/datasources/face_auth_local_data_source.dart';
import 'package:tessie_app/core/data/datasources/face_auth_remote_data_source.dart';
import 'package:tessie_app/core/data/models/face_auth_response_dto.dart';
import 'package:tessie_app/core/data/models/face_enrollment_dto.dart';
import 'package:tessie_app/core/data/repositories/face_auth_repository_impl.dart';
import 'package:tessie_app/core/domain/failures/failure.dart';

// Generate mocks
@GenerateMocks([FaceAuthLocalDataSource, FaceAuthRemoteDataSource])
import 'face_auth_repository_impl_test.mocks.dart';

void main() {
  late FaceAuthRepositoryImpl repository;
  late MockFaceAuthLocalDataSource mockLocalDataSource;
  late MockFaceAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockFaceAuthLocalDataSource();
    mockRemoteDataSource = MockFaceAuthRemoteDataSource();
    repository = FaceAuthRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  final testUserId = 'user123';
  final testDeviceId = 'device789';
  final testTimestamp = Timestamp.now();

  final testEnrollmentDto = FaceEnrollmentDto(
    userId: testUserId,
    enrollmentId: 'enroll456',
    enrolledAt: testTimestamp,
    isActive: true,
    deviceId: testDeviceId,
    biometricType: 'face',
  );

  final testAuthResponseDto = FaceAuthResponseDto(
    isAuthenticated: true,
    userId: testUserId,
    sessionToken: 'token456',
    authenticatedAt: testTimestamp,
    expiresAt: Timestamp.fromDate(
      DateTime.now().add(const Duration(hours: 24)),
    ),
    confidenceScore: 0.95,
    enrollmentId: 'enroll456',
    method: 'faceBiometric',
  );

  group('authenticateWithFace', () {
    test('should return FaceAuthResponseEntity when authentication successful',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.authenticateLocally(any))
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.getEnrollment(testUserId))
          .thenAnswer((_) async => testEnrollmentDto);
      when(mockRemoteDataSource.verifyAuthentication(
        userId: testUserId,
        enrollmentId: anyNamed('enrollmentId'),
      )).thenAnswer((_) async => testAuthResponseDto);
      when(mockLocalDataSource.storeSessionToken(any, any))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.authenticateWithFace(
        userId: testUserId,
        reason: 'Test authentication',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (entity) {
          expect(entity.isAuthenticated, true);
          expect(entity.userId, testUserId);
          expect(entity.sessionToken, 'token456');
        },
      );

      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
      verify(mockLocalDataSource.isFaceEnrolled(testUserId)).called(1);
      verify(mockLocalDataSource.authenticateLocally('Test authentication'))
          .called(1);
      verify(mockLocalDataSource.getEnrollment(testUserId)).called(1);
      verify(mockRemoteDataSource.verifyAuthentication(
        userId: testUserId,
        enrollmentId: 'enroll456',
      )).called(1);
      verify(mockLocalDataSource.storeSessionToken(
        testUserId,
        'token456',
      )).called(1);
    });

    test(
        'should return BiometricNotAvailableFailure when biometric not available',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.authenticateWithFace(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<BiometricNotAvailableFailure>()),
        (_) => fail('Should return failure'),
      );

      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
      verifyNever(mockLocalDataSource.isFaceEnrolled(any));
    });

    test('should return FaceNotEnrolledException when face not enrolled',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.authenticateWithFace(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<FaceNotEnrolledException>()),
        (_) => fail('Should return failure'),
      );

      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
      verify(mockLocalDataSource.isFaceEnrolled(testUserId)).called(1);
      verifyNever(mockLocalDataSource.authenticateLocally(any));
    });

    test(
        'should return BiometricAuthenticationFailure when local auth fails',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.authenticateLocally(any))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.authenticateWithFace(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) =>
            expect(failure, isA<BiometricAuthenticationFailure>()),
        (_) => fail('Should return failure'),
      );

      verify(mockLocalDataSource.authenticateLocally(any)).called(1);
      verifyNever(mockRemoteDataSource.verifyAuthentication(
        userId: anyNamed('userId'),
        enrollmentId: anyNamed('enrollmentId'),
      ));
    });

    test('should handle exception and return appropriate failure', () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenThrow(Exception('Biometric not available'));

      // Act
      final result = await repository.authenticateWithFace(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<BiometricNotAvailableFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('enrollFaceBiometric', () {
    test('should return FaceEnrollmentEntity when enrollment successful',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.authenticateLocally(any))
          .thenAnswer((_) async => true);
      when(mockRemoteDataSource.registerEnrollment(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async => testEnrollmentDto);
      when(mockLocalDataSource.storeEnrollment(any))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.enrollFaceBiometric(
        userId: testUserId,
        deviceId: testDeviceId,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return success'),
        (entity) {
          expect(entity.userId, testUserId);
          expect(entity.enrollmentId, 'enroll456');
          expect(entity.isActive, true);
        },
      );

      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
      verify(mockLocalDataSource.authenticateLocally(any)).called(1);
      verify(mockRemoteDataSource.registerEnrollment(
        userId: testUserId,
        deviceId: testDeviceId,
      )).called(1);
      verify(mockLocalDataSource.storeEnrollment(testEnrollmentDto)).called(1);
    });

    test(
        'should return BiometricNotAvailableFailure when biometric not available',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.enrollFaceBiometric(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<BiometricNotAvailableFailure>()),
        (_) => fail('Should return failure'),
      );

      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
      verifyNever(mockLocalDataSource.authenticateLocally(any));
    });

    test(
        'should return BiometricAuthenticationFailure when auth fails during enrollment',
        () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.authenticateLocally(any))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.enrollFaceBiometric(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) =>
            expect(failure, isA<BiometricAuthenticationFailure>()),
        (_) => fail('Should return failure'),
      );

      verifyNever(mockRemoteDataSource.registerEnrollment(
        userId: anyNamed('userId'),
        deviceId: anyNamed('deviceId'),
      ));
    });

    test('should handle enrollment failure from remote source', () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);
      when(mockLocalDataSource.authenticateLocally(any))
          .thenAnswer((_) async => true);
      when(mockRemoteDataSource.registerEnrollment(
        userId: testUserId,
        deviceId: anyNamed('deviceId'),
      )).thenThrow(Exception('register enrollment failed'));

      // Act
      final result = await repository.enrollFaceBiometric(
        userId: testUserId,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<FaceEnrollmentFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('isFaceEnrolled', () {
    test('should return true when face is enrolled', () async {
      // Arrange
      when(mockLocalDataSource.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.isFaceEnrolled(testUserId);

      // Assert
      expect(result, const Right(true));
      verify(mockLocalDataSource.isFaceEnrolled(testUserId)).called(1);
    });

    test('should return false when face is not enrolled', () async {
      // Arrange
      when(mockLocalDataSource.isFaceEnrolled(testUserId))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.isFaceEnrolled(testUserId);

      // Assert
      expect(result, const Right(false));
      verify(mockLocalDataSource.isFaceEnrolled(testUserId)).called(1);
    });
  });

  group('deleteFaceEnrollment', () {
    test('should delete enrollment from both local and remote sources',
        () async {
      // Arrange
      when(mockLocalDataSource.deleteEnrollment(testUserId))
          .thenAnswer((_) async => {});
      when(mockRemoteDataSource.deleteEnrollment(testUserId))
          .thenAnswer((_) async => {});
      when(mockLocalDataSource.deleteSessionToken(testUserId))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteFaceEnrollment(testUserId);

      // Assert
      expect(result.isRight(), true);
      verify(mockLocalDataSource.deleteEnrollment(testUserId)).called(1);
      verify(mockRemoteDataSource.deleteEnrollment(testUserId)).called(1);
      verify(mockLocalDataSource.deleteSessionToken(testUserId)).called(1);
    });

    test('should handle deletion failure', () async {
      // Arrange
      when(mockLocalDataSource.deleteEnrollment(testUserId))
          .thenThrow(Exception('Deletion failed'));

      // Act
      final result = await repository.deleteFaceEnrollment(testUserId);

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('isBiometricAvailable', () {
    test('should return true when biometric is available', () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.isBiometricAvailable();

      // Assert
      expect(result, const Right(true));
      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
    });

    test('should return false when biometric is not available', () async {
      // Arrange
      when(mockLocalDataSource.isBiometricAvailable())
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.isBiometricAvailable();

      // Assert
      expect(result, const Right(false));
      verify(mockLocalDataSource.isBiometricAvailable()).called(1);
    });
  });

  group('verifySession', () {
    test('should return true when session is valid', () async {
      // Arrange
      const sessionToken = 'token456';
      when(mockRemoteDataSource.verifySessionToken(sessionToken))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.verifySession(sessionToken);

      // Assert
      expect(result, const Right(true));
      verify(mockRemoteDataSource.verifySessionToken(sessionToken)).called(1);
    });

    test('should return false when session is invalid', () async {
      // Arrange
      const sessionToken = 'invalid_token';
      when(mockRemoteDataSource.verifySessionToken(sessionToken))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.verifySession(sessionToken);

      // Assert
      expect(result, const Right(false));
      verify(mockRemoteDataSource.verifySessionToken(sessionToken)).called(1);
    });
  });

  group('invalidateSession', () {
    test('should successfully invalidate session', () async {
      // Arrange
      const sessionToken = 'token456';
      when(mockRemoteDataSource.invalidateSession(sessionToken))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.invalidateSession(sessionToken);

      // Assert
      expect(result.isRight(), true);
      verify(mockRemoteDataSource.invalidateSession(sessionToken)).called(1);
    });

    test('should handle invalidation failure', () async {
      // Arrange
      const sessionToken = 'token456';
      when(mockRemoteDataSource.invalidateSession(sessionToken))
          .thenThrow(Exception('Invalidation failed'));

      // Act
      final result = await repository.invalidateSession(sessionToken);

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
