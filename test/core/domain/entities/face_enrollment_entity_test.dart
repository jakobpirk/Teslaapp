import 'package:flutter_test/flutter_test.dart';
import 'package:tessie_app/core/domain/entities/face_enrollment_entity.dart';

void main() {
  group('FaceEnrollmentEntity', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0, 0);

    test('should create entity with all required fields', () {
      // Arrange & Act
      final entity = FaceEnrollmentEntity(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        deviceId: 'device789',
        biometricType: BiometricTypeEntity.face,
      );

      // Assert
      expect(entity.userId, 'user123');
      expect(entity.enrollmentId, 'enroll456');
      expect(entity.enrolledAt, testDateTime);
      expect(entity.isActive, true);
      expect(entity.deviceId, 'device789');
      expect(entity.biometricType, BiometricTypeEntity.face);
    });

    test('should create entity without optional fields', () {
      // Arrange & Act
      final entity = FaceEnrollmentEntity(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        biometricType: BiometricTypeEntity.face,
      );

      // Assert
      expect(entity.deviceId, isNull);
    });

    test('should support copyWith for all fields', () {
      // Arrange
      final original = FaceEnrollmentEntity(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        deviceId: 'device789',
        biometricType: BiometricTypeEntity.face,
      );

      // Act
      final copied = original.copyWith(
        userId: 'user999',
        isActive: false,
        biometricType: BiometricTypeEntity.fingerprint,
      );

      // Assert
      expect(copied.userId, 'user999');
      expect(copied.enrollmentId, 'enroll456'); // unchanged
      expect(copied.isActive, false);
      expect(copied.deviceId, 'device789'); // unchanged
      expect(copied.biometricType, BiometricTypeEntity.fingerprint);
    });

    test('should implement equality correctly', () {
      // Arrange
      final entity1 = FaceEnrollmentEntity(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        biometricType: BiometricTypeEntity.face,
      );

      final entity2 = FaceEnrollmentEntity(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        biometricType: BiometricTypeEntity.face,
      );

      final entity3 = FaceEnrollmentEntity(
        userId: 'user999',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        biometricType: BiometricTypeEntity.face,
      );

      // Assert
      expect(entity1, equals(entity2));
      expect(entity1, isNot(equals(entity3)));
      expect(entity1.hashCode, equals(entity2.hashCode));
    });
  });

  group('BiometricTypeEntity', () {
    test('should have correct display names', () {
      expect(
        BiometricTypeEntity.face.displayName,
        'Face Recognition',
      );
      expect(
        BiometricTypeEntity.fingerprint.displayName,
        'Fingerprint',
      );
      expect(
        BiometricTypeEntity.iris.displayName,
        'Iris Scan',
      );
      expect(
        BiometricTypeEntity.voice.displayName,
        'Voice Recognition',
      );
    });

    test('should have all biometric types', () {
      expect(BiometricTypeEntity.values.length, 4);
      expect(BiometricTypeEntity.values, contains(BiometricTypeEntity.face));
      expect(
        BiometricTypeEntity.values,
        contains(BiometricTypeEntity.fingerprint),
      );
      expect(BiometricTypeEntity.values, contains(BiometricTypeEntity.iris));
      expect(BiometricTypeEntity.values, contains(BiometricTypeEntity.voice));
    });
  });
}
