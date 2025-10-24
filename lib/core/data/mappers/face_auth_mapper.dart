import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/face_auth_response_entity.dart';
import '../../domain/entities/face_enrollment_entity.dart';
import '../models/face_auth_response_dto.dart';
import '../models/face_enrollment_dto.dart';

/// Mapper for converting between Face Enrollment DTOs and Entities
class FaceEnrollmentMapper {
  /// Convert DTO to Entity
  static FaceEnrollmentEntity toEntity(FaceEnrollmentDto dto) {
    return FaceEnrollmentEntity(
      userId: dto.userId,
      enrollmentId: dto.enrollmentId,
      enrolledAt: dto.enrolledAt.toDate(),
      isActive: dto.isActive,
      deviceId: dto.deviceId,
      biometricType: _mapBiometricType(dto.biometricType),
    );
  }

  /// Convert Entity to DTO
  static FaceEnrollmentDto toDto(FaceEnrollmentEntity entity) {
    return FaceEnrollmentDto(
      userId: entity.userId,
      enrollmentId: entity.enrollmentId,
      enrolledAt: Timestamp.fromDate(entity.enrolledAt),
      isActive: entity.isActive,
      deviceId: entity.deviceId,
      biometricType: _mapBiometricTypeToString(entity.biometricType),
    );
  }

  /// Map string to BiometricTypeEntity enum
  static BiometricTypeEntity _mapBiometricType(String type) {
    switch (type.toLowerCase()) {
      case 'face':
        return BiometricTypeEntity.face;
      case 'fingerprint':
        return BiometricTypeEntity.fingerprint;
      case 'iris':
        return BiometricTypeEntity.iris;
      case 'voice':
        return BiometricTypeEntity.voice;
      default:
        return BiometricTypeEntity.face;
    }
  }

  /// Map BiometricTypeEntity enum to string
  static String _mapBiometricTypeToString(BiometricTypeEntity type) {
    switch (type) {
      case BiometricTypeEntity.face:
        return 'face';
      case BiometricTypeEntity.fingerprint:
        return 'fingerprint';
      case BiometricTypeEntity.iris:
        return 'iris';
      case BiometricTypeEntity.voice:
        return 'voice';
    }
  }
}

/// Mapper for converting between Face Auth Response DTOs and Entities
class FaceAuthResponseMapper {
  /// Convert DTO to Entity
  static FaceAuthResponseEntity toEntity(FaceAuthResponseDto dto) {
    return FaceAuthResponseEntity(
      isAuthenticated: dto.isAuthenticated,
      userId: dto.userId,
      sessionToken: dto.sessionToken,
      authenticatedAt: dto.authenticatedAt.toDate(),
      expiresAt: dto.expiresAt.toDate(),
      confidenceScore: dto.confidenceScore,
      enrollmentId: dto.enrollmentId,
      method: _mapAuthenticationMethod(dto.method),
    );
  }

  /// Convert Entity to DTO
  static FaceAuthResponseDto toDto(FaceAuthResponseEntity entity) {
    return FaceAuthResponseDto(
      isAuthenticated: entity.isAuthenticated,
      userId: entity.userId,
      sessionToken: entity.sessionToken,
      authenticatedAt: Timestamp.fromDate(entity.authenticatedAt),
      expiresAt: Timestamp.fromDate(entity.expiresAt),
      confidenceScore: entity.confidenceScore,
      enrollmentId: entity.enrollmentId,
      method: _mapAuthenticationMethodToString(entity.method),
    );
  }

  /// Map string to AuthenticationMethodEntity enum
  static AuthenticationMethodEntity _mapAuthenticationMethod(String method) {
    switch (method.toLowerCase()) {
      case 'facebiometric':
      case 'face_biometric':
        return AuthenticationMethodEntity.faceBiometric;
      case 'facewithliveness':
      case 'face_with_liveness':
        return AuthenticationMethodEntity.faceWithLiveness;
      case 'facewithpin':
      case 'face_with_pin':
        return AuthenticationMethodEntity.faceWithPin;
      case 'fallbackpassword':
      case 'fallback_password':
        return AuthenticationMethodEntity.fallbackPassword;
      default:
        return AuthenticationMethodEntity.faceBiometric;
    }
  }

  /// Map AuthenticationMethodEntity enum to string
  static String _mapAuthenticationMethodToString(
    AuthenticationMethodEntity method,
  ) {
    switch (method) {
      case AuthenticationMethodEntity.faceBiometric:
        return 'faceBiometric';
      case AuthenticationMethodEntity.faceWithLiveness:
        return 'faceWithLiveness';
      case AuthenticationMethodEntity.faceWithPin:
        return 'faceWithPin';
      case AuthenticationMethodEntity.fallbackPassword:
        return 'fallbackPassword';
    }
  }
}
