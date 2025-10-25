import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/face_enrollment_dto.dart';
import '../exceptions/data_exceptions.dart';

/// Abstract interface for local face authentication operations
abstract class FaceAuthLocalDataSource {
  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable();

  /// Check if face is enrolled locally for the user
  Future<bool> isFaceEnrolled(String userId);

  /// Authenticate using biometric (face/fingerprint)
  Future<bool> authenticateLocally(String reason);

  /// Store enrollment data locally
  Future<void> storeEnrollment(FaceEnrollmentDto enrollment);

  /// Get enrollment data from local storage
  Future<FaceEnrollmentDto?> getEnrollment(String userId);

  /// Delete enrollment data from local storage
  Future<void> deleteEnrollment(String userId);

  /// Store authentication session token securely
  Future<void> storeSessionToken(String userId, String token);

  /// Get stored session token
  Future<String?> getSessionToken(String userId);

  /// Delete session token
  Future<void> deleteSessionToken(String userId);
}

/// Web implementation of local face authentication data source
/// Biometric authentication is not available on web, so this is a stub implementation
class FaceAuthLocalDataSourceImpl implements FaceAuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const String _enrollmentKeyPrefix = 'face_enrollment_';
  static const String _sessionTokenKeyPrefix = 'face_session_';

  FaceAuthLocalDataSourceImpl({
    Object? localAuth, // Ignored on web, here for API compatibility
    required this.secureStorage,
  });

  @override
  Future<bool> isBiometricAvailable() async {
    // Biometric authentication is not available on web
    return false;
  }

  @override
  Future<bool> isFaceEnrolled(String userId) async {
    // Web doesn't support face authentication
    return false;
  }

  @override
  Future<bool> authenticateLocally(String reason) async {
    // Web doesn't support biometric authentication
    throw BiometricException(
      'Biometric authentication is not available on web',
      BiometricErrorType.notAvailable,
      null,
    );
  }

  @override
  Future<void> storeEnrollment(FaceEnrollmentDto enrollment) async {
    try {
      final enrollmentJson = enrollment.toJson();
      final enrollmentString = jsonEncode(enrollmentJson);

      await secureStorage.write(
        key: '$_enrollmentKeyPrefix${enrollment.userId}',
        value: enrollmentString,
      );
    } catch (e) {
      throw StorageException(
        'Failed to store enrollment',
        e,
        '$_enrollmentKeyPrefix${enrollment.userId}',
      );
    }
  }

  @override
  Future<FaceEnrollmentDto?> getEnrollment(String userId) async {
    try {
      final enrollmentString =
          await secureStorage.read(key: '$_enrollmentKeyPrefix$userId');

      if (enrollmentString == null) {
        return null;
      }

      try {
        // Parse the stored JSON string back to DTO
        final enrollmentJson = jsonDecode(enrollmentString) as Map<String, dynamic>;
        return FaceEnrollmentDto.fromJson(enrollmentJson);
      } catch (e) {
        throw ParseException(
          'Failed to parse enrollment data',
          e,
        );
      }
    } catch (e) {
      if (e is ParseException) {
        rethrow;
      }
      throw StorageException(
        'Failed to get enrollment',
        e,
        '$_enrollmentKeyPrefix$userId',
      );
    }
  }

  @override
  Future<void> deleteEnrollment(String userId) async {
    try {
      await secureStorage.delete(key: '$_enrollmentKeyPrefix$userId');
    } catch (e) {
      throw StorageException(
        'Failed to delete enrollment',
        e,
        '$_enrollmentKeyPrefix$userId',
      );
    }
  }

  @override
  Future<void> storeSessionToken(String userId, String token) async {
    try {
      await secureStorage.write(
        key: '$_sessionTokenKeyPrefix$userId',
        value: token,
      );
    } catch (e) {
      throw StorageException(
        'Failed to store session token',
        e,
        '$_sessionTokenKeyPrefix$userId',
      );
    }
  }

  @override
  Future<String?> getSessionToken(String userId) async {
    try {
      return await secureStorage.read(key: '$_sessionTokenKeyPrefix$userId');
    } catch (e) {
      throw StorageException(
        'Failed to get session token',
        e,
        '$_sessionTokenKeyPrefix$userId',
      );
    }
  }

  @override
  Future<void> deleteSessionToken(String userId) async {
    try {
      await secureStorage.delete(key: '$_sessionTokenKeyPrefix$userId');
    } catch (e) {
      throw StorageException(
        'Failed to delete session token',
        e,
        '$_sessionTokenKeyPrefix$userId',
      );
    }
  }
}
