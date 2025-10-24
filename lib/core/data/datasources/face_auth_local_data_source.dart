import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Implementation of local face authentication data source
class FaceAuthLocalDataSourceImpl implements FaceAuthLocalDataSource {
  final LocalAuthentication localAuth;
  final FlutterSecureStorage secureStorage;

  static const String _enrollmentKeyPrefix = 'face_enrollment_';
  static const String _sessionTokenKeyPrefix = 'face_session_';

  FaceAuthLocalDataSourceImpl({
    required this.localAuth,
    required this.secureStorage,
  });

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device supports biometric authentication
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return false;
      }

      // Get available biometrics
      final List<BiometricType> availableBiometrics =
          await localAuth.getAvailableBiometrics();

      // Check if face or fingerprint is available
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      throw BiometricException(
        'Failed to check biometric availability',
        BiometricErrorType.hardwareError,
        e,
      );
    }
  }

  @override
  Future<bool> isFaceEnrolled(String userId) async {
    try {
      final enrollmentData =
          await secureStorage.read(key: '$_enrollmentKeyPrefix$userId');
      return enrollmentData != null;
    } catch (e) {
      throw StorageException(
        'Failed to check face enrollment',
        e,
        '$_enrollmentKeyPrefix$userId',
      );
    }
  }

  @override
  Future<bool> authenticateLocally(String reason) async {
    try {
      final bool didAuthenticate = await localAuth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Face Authentication',
            cancelButton: 'Cancel',
            biometricHint: 'Verify your identity',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            lockOut: 'Face ID is locked. Please use passcode.',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      // Check for specific error types from the error message
      final errorMessage = e.toString().toLowerCase();
      BiometricErrorType errorType;

      if (errorMessage.contains('cancel')) {
        errorType = BiometricErrorType.cancelled;
      } else if (errorMessage.contains('lockout') || errorMessage.contains('locked')) {
        errorType = BiometricErrorType.lockout;
      } else if (errorMessage.contains('not available')) {
        errorType = BiometricErrorType.notAvailable;
      } else if (errorMessage.contains('not enrolled')) {
        errorType = BiometricErrorType.notEnrolled;
      } else {
        errorType = BiometricErrorType.authenticationFailed;
      }

      throw BiometricException(
        'Biometric authentication failed',
        errorType,
        e,
      );
    }
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
