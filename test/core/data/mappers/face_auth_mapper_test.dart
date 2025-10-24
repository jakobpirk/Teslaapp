import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tessie_app/core/data/mappers/face_auth_mapper.dart';
import 'package:tessie_app/core/data/models/face_auth_response_dto.dart';
import 'package:tessie_app/core/data/models/face_enrollment_dto.dart';
import 'package:tessie_app/core/domain/entities/face_auth_response_entity.dart';
import 'package:tessie_app/core/domain/entities/face_enrollment_entity.dart';

void main() {
  group('FaceEnrollmentMapper', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 1, 12, 0, 0));
    final testDateTime = DateTime(2024, 1, 1, 12, 0, 0);

    test('should correctly map DTO to Entity', () {
      // Arrange
      final dto = FaceEnrollmentDto(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testTimestamp,
        isActive: true,
        deviceId: 'device789',
        biometricType: 'face',
      );

      // Act
      final entity = FaceEnrollmentMapper.toEntity(dto);

      // Assert
      expect(entity.userId, 'user123');
      expect(entity.enrollmentId, 'enroll456');
      expect(entity.enrolledAt, testDateTime);
      expect(entity.isActive, true);
      expect(entity.deviceId, 'device789');
      expect(entity.biometricType, BiometricTypeEntity.face);
    });

    test('should correctly map Entity to DTO', () {
      // Arrange
      const entity = FaceEnrollmentEntity(
        userId: 'user123',
        enrollmentId: 'enroll456',
        enrolledAt: testDateTime,
        isActive: true,
        deviceId: 'device789',
        biometricType: BiometricTypeEntity.face,
      );

      // Act
      final dto = FaceEnrollmentMapper.toDto(entity);

      // Assert
      expect(dto.userId, 'user123');
      expect(dto.enrollmentId, 'enroll456');
      expect(dto.enrolledAt, testTimestamp);
      expect(dto.isActive, true);
      expect(dto.deviceId, 'device789');
      expect(dto.biometricType, 'face');
    });

    test('should map all biometric types correctly from DTO to Entity', () {
      final testCases = {
        'face': BiometricTypeEntity.face,
        'fingerprint': BiometricTypeEntity.fingerprint,
        'iris': BiometricTypeEntity.iris,
        'voice': BiometricTypeEntity.voice,
        'unknown': BiometricTypeEntity.face, // default
      };

      for (final entry in testCases.entries) {
        final dto = FaceEnrollmentDto(
          userId: 'user123',
          enrollmentId: 'enroll456',
          enrolledAt: testTimestamp,
          isActive: true,
          biometricType: entry.key,
        );

        final entity = FaceEnrollmentMapper.toEntity(dto);
        expect(entity.biometricType, entry.value);
      }
    });

    test('should map all biometric types correctly from Entity to DTO', () {
      final testCases = {
        BiometricTypeEntity.face: 'face',
        BiometricTypeEntity.fingerprint: 'fingerprint',
        BiometricTypeEntity.iris: 'iris',
        BiometricTypeEntity.voice: 'voice',
      };

      for (final entry in testCases.entries) {
        final entity = FaceEnrollmentEntity(
          userId: 'user123',
          enrollmentId: 'enroll456',
          enrolledAt: testDateTime,
          isActive: true,
          biometricType: entry.key,
        );

        final dto = FaceEnrollmentMapper.toDto(entity);
        expect(dto.biometricType, entry.value);
      }
    });
  });

  group('FaceAuthResponseMapper', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 1, 12, 0, 0));
    final testDateTime = DateTime(2024, 1, 1, 12, 0, 0);

    test('should correctly map DTO to Entity', () {
      // Arrange
      final dto = FaceAuthResponseDto(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: testTimestamp,
        expiresAt: testTimestamp,
        confidenceScore: 0.95,
        enrollmentId: 'enroll789',
        method: 'faceBiometric',
      );

      // Act
      final entity = FaceAuthResponseMapper.toEntity(dto);

      // Assert
      expect(entity.isAuthenticated, true);
      expect(entity.userId, 'user123');
      expect(entity.sessionToken, 'token456');
      expect(entity.authenticatedAt, testDateTime);
      expect(entity.expiresAt, testDateTime);
      expect(entity.confidenceScore, 0.95);
      expect(entity.enrollmentId, 'enroll789');
      expect(entity.method, AuthenticationMethodEntity.faceBiometric);
    });

    test('should correctly map Entity to DTO', () {
      // Arrange
      const entity = FaceAuthResponseEntity(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: testDateTime,
        expiresAt: testDateTime,
        confidenceScore: 0.95,
        enrollmentId: 'enroll789',
        method: AuthenticationMethodEntity.faceBiometric,
      );

      // Act
      final dto = FaceAuthResponseMapper.toDto(entity);

      // Assert
      expect(dto.isAuthenticated, true);
      expect(dto.userId, 'user123');
      expect(dto.sessionToken, 'token456');
      expect(dto.authenticatedAt, testTimestamp);
      expect(dto.expiresAt, testTimestamp);
      expect(dto.confidenceScore, 0.95);
      expect(dto.enrollmentId, 'enroll789');
      expect(dto.method, 'faceBiometric');
    });

    test('should map all authentication methods correctly from DTO to Entity',
        () {
      final testCases = {
        'faceBiometric': AuthenticationMethodEntity.faceBiometric,
        'face_biometric': AuthenticationMethodEntity.faceBiometric,
        'faceWithLiveness': AuthenticationMethodEntity.faceWithLiveness,
        'face_with_liveness': AuthenticationMethodEntity.faceWithLiveness,
        'faceWithPin': AuthenticationMethodEntity.faceWithPin,
        'face_with_pin': AuthenticationMethodEntity.faceWithPin,
        'fallbackPassword': AuthenticationMethodEntity.fallbackPassword,
        'fallback_password': AuthenticationMethodEntity.fallbackPassword,
        'unknown': AuthenticationMethodEntity.faceBiometric, // default
      };

      for (final entry in testCases.entries) {
        final dto = FaceAuthResponseDto(
          isAuthenticated: true,
          userId: 'user123',
          sessionToken: 'token456',
          authenticatedAt: testTimestamp,
          expiresAt: testTimestamp,
          confidenceScore: 0.95,
          method: entry.key,
        );

        final entity = FaceAuthResponseMapper.toEntity(dto);
        expect(entity.method, entry.value);
      }
    });

    test('should map all authentication methods correctly from Entity to DTO',
        () {
      final testCases = {
        AuthenticationMethodEntity.faceBiometric: 'faceBiometric',
        AuthenticationMethodEntity.faceWithLiveness: 'faceWithLiveness',
        AuthenticationMethodEntity.faceWithPin: 'faceWithPin',
        AuthenticationMethodEntity.fallbackPassword: 'fallbackPassword',
      };

      for (final entry in testCases.entries) {
        final entity = FaceAuthResponseEntity(
          isAuthenticated: true,
          userId: 'user123',
          sessionToken: 'token456',
          authenticatedAt: testDateTime,
          expiresAt: testDateTime,
          confidenceScore: 0.95,
          method: entry.key,
        );

        final dto = FaceAuthResponseMapper.toDto(entity);
        expect(dto.method, entry.value);
      }
    });

    test('should preserve all data in round-trip conversion', () {
      // Arrange
      final originalDto = FaceAuthResponseDto(
        isAuthenticated: true,
        userId: 'user123',
        sessionToken: 'token456',
        authenticatedAt: testTimestamp,
        expiresAt: testTimestamp,
        confidenceScore: 0.95,
        enrollmentId: 'enroll789',
        method: 'faceWithLiveness',
      );

      // Act
      final entity = FaceAuthResponseMapper.toEntity(originalDto);
      final roundTripDto = FaceAuthResponseMapper.toDto(entity);

      // Assert
      expect(roundTripDto.isAuthenticated, originalDto.isAuthenticated);
      expect(roundTripDto.userId, originalDto.userId);
      expect(roundTripDto.sessionToken, originalDto.sessionToken);
      expect(roundTripDto.confidenceScore, originalDto.confidenceScore);
      expect(roundTripDto.enrollmentId, originalDto.enrollmentId);
      expect(roundTripDto.method, originalDto.method);
    });
  });
}
