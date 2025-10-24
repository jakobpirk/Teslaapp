import 'package:flutter_test/flutter_test.dart';
import 'package:tessie_app/core/domain/entities/face_auth_response_entity.dart';

void main() {
  group('FaceAuthResponseEntity', () {
    final now = DateTime.now();
    final future = now.add(const Duration(hours: 24));
    final past = now.subtract(const Duration(hours: 1));

    test('should create entity with all required fields', () {
      // Arrange & Act
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        enrollmentId: 'enroll789',
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Assert
      expect(entity.isAuthenticated, true);
      expect(entity.userId, 'user123');
      expect(entity.sessionToken, 'token456');
      expect(entity.authenticatedAt, now);
      expect(entity.expiresAt, future);
      expect(entity.confidenceScore, 0.95);
      expect(entity.enrollmentId, 'enroll789');
      expect(entity.method, AuthenticationMethodEntity.faceBiometric);
    });

    test('should create entity without optional fields', () {
      // Arrange & Act
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Assert
      expect(entity.enrollmentId, isNull);
    });

    test('isValid should return true when session is not expired', () {
      // Arrange
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act & Assert
      expect(entity.isValid, true);
    });

    test('isValid should return false when session is expired', () {
      // Arrange
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: past.subtract(const Duration(days: 2)),
        expiresAt: past,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act & Assert
      expect(entity.isValid, false);
    });

    test('remainingMinutes should return correct value for valid session', () {
      // Arrange
      final expiresIn2Hours = now.add(const Duration(hours: 2));
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: expiresIn2Hours,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act & Assert
      expect(entity.remainingMinutes, greaterThan(100));
      expect(entity.remainingMinutes, lessThanOrEqualTo(120));
    });

    test('remainingMinutes should return 0 for expired session', () {
      // Arrange
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: past.subtract(const Duration(days: 2)),
        expiresAt: past,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act & Assert
      expect(entity.remainingMinutes, 0);
    });

    test('meetsConfidenceThreshold should return true when score meets threshold',
        () {
      // Arrange
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act & Assert
      expect(entity.meetsConfidenceThreshold(0.90), true);
      expect(entity.meetsConfidenceThreshold(0.95), true);
    });

    test(
        'meetsConfidenceThreshold should return false when score below threshold',
        () {
      // Arrange
      final entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.85,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act & Assert
      expect(entity.meetsConfidenceThreshold(0.90), false);
      expect(entity.meetsConfidenceThreshold(0.95), false);
    });

    test('should support copyWith for all fields', () {
      // Arrange
      final original = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        enrollmentId: 'enroll789',
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act
      final copied = original.copyWith(
        isAuthenticated: false,
        confidenceScore: 0.80,
        method: AuthenticationMethodEntity.faceWithLiveness,
      );

      // Assert
      expect(copied.isAuthenticated, false);
      expect(copied.userId, 'user123'); // unchanged
      expect(copied.confidenceScore, 0.80);
      expect(copied.method, AuthenticationMethodEntity.faceWithLiveness);
    });

    test('should implement equality correctly', () {
      // Arrange
      final entity1 = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      final entity2 = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      final entity3 = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user999', // different
        sessionToken: 'token456',
        authenticatedAt: now,
        expiresAt: future,
        confidenceScore: 0.95,
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Assert
      expect(entity1, equals(entity2));
      expect(entity1, isNot(equals(entity3)));
      expect(entity1.hashCode, equals(entity2.hashCode));
    });
  });

  group('AuthenticationMethodEntity', () {
    test('should have correct display names', () {
      expect(
        AuthenticationMethodEntity.faceBiometric.displayName,
        'Face Biometric',
      );
      expect(
        AuthenticationMethodEntity.faceWithLiveness.displayName,
        'Face with Liveness Detection',
      );
      expect(
        AuthenticationMethodEntity.faceWithPin.displayName,
        'Face with PIN',
      );
      expect(
        AuthenticationMethodEntity.fallbackPassword.displayName,
        'Password (Fallback)',
      );
    });

    test('isFaceBased should return true for face-based methods', () {
      expect(AuthenticationMethodEntity.faceBiometric.isFaceBased, true);
      expect(AuthenticationMethodEntity.faceWithLiveness.isFaceBased, true);
      expect(AuthenticationMethodEntity.faceWithPin.isFaceBased, true);
    });

    test('isFaceBased should return false for non-face methods', () {
      expect(AuthenticationMethodEntity.fallbackPassword.isFaceBased, false);
    });

    test('should have all authentication methods', () {
      expect(AuthenticationMethodEntity.values.length, 4);
      expect(
        AuthenticationMethodEntity.values,
        contains(AuthenticationMethodEntity.faceBiometric),
      );
      expect(
        AuthenticationMethodEntity.values,
        contains(AuthenticationMethodEntity.faceWithLiveness),
      );
      expect(
        AuthenticationMethodEntity.values,
        contains(AuthenticationMethodEntity.faceWithPin),
      );
      expect(
        AuthenticationMethodEntity.values,
        contains(AuthenticationMethodEntity.fallbackPassword),
      );
    });
  });
}
