import 'package:dio/dio.dart';
import '../models/face_enrollment_dto.dart';
import '../models/face_auth_response_dto.dart';

/// HTTP-based implementation of FaceAuthRemoteDataSource
/// This replaces Firebase Firestore with REST API calls
class FaceAuthHttpDataSource {
  final Dio dio;
  final String baseUrl;
  static const String _endpoint = '/api/v1/face-auth';

  FaceAuthHttpDataSource({
    required this.dio,
    required this.baseUrl,
  });

  /// Verify face authentication with remote server
  Future<FaceAuthResponseDto> verifyAuthentication({
    required String userId,
    required String enrollmentId,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl$_endpoint/verify',
        data: {
          'user_id': userId,
          'enrollment_id': enrollmentId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _authResponseFromJson(response.data);
      } else {
        throw Exception('Failed to verify authentication: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to verify authentication: $e');
    }
  }

  /// Register face enrollment with remote server
  Future<FaceEnrollmentDto> registerEnrollment({
    required String userId,
    String? deviceId,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl$_endpoint/enrollments',
        data: {
          'user_id': userId,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _enrollmentFromJson(response.data);
      } else {
        throw Exception('Failed to register enrollment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to register enrollment: $e');
    }
  }

  /// Get enrollment from remote server
  Future<FaceEnrollmentDto> getEnrollment(String userId) async {
    try {
      final response = await dio.get('$baseUrl$_endpoint/enrollments/$userId');

      if (response.statusCode == 200) {
        return _enrollmentFromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('No active enrollment found for user');
      } else {
        throw Exception('Failed to get enrollment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get enrollment: $e');
    }
  }

  /// Delete enrollment from remote server
  Future<void> deleteEnrollment(String userId) async {
    try {
      final response = await dio.delete('$baseUrl$_endpoint/enrollments/$userId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete enrollment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete enrollment: $e');
    }
  }

  /// Verify session token with remote server
  Future<bool> verifySessionToken(String sessionToken) async {
    try {
      final response = await dio.post(
        '$baseUrl$_endpoint/sessions/verify',
        data: {
          'session_token': sessionToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['valid'] as bool? ?? false;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Failed to verify session token: $e');
    }
  }

  /// Invalidate session on remote server
  Future<void> invalidateSession(String sessionToken) async {
    try {
      final response = await dio.post(
        '$baseUrl$_endpoint/sessions/invalidate',
        data: {
          'session_token': sessionToken,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to invalidate session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to invalidate session: $e');
    }
  }

  /// Convert API JSON to FaceEnrollmentDto
  FaceEnrollmentDto _enrollmentFromJson(Map<String, dynamic> json) {
    return FaceEnrollmentDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      isActive: json['is_active'] as bool,
      deviceId: json['device_id'] as String?,
      biometricType: json['biometric_type'] as String? ?? 'face',
    );
  }

  /// Convert API JSON to FaceAuthResponseDto
  FaceAuthResponseDto _authResponseFromJson(Map<String, dynamic> json) {
    return FaceAuthResponseDto(
      sessionToken: json['session_token'] as String,
      userId: json['user_id'] as String,
      enrollmentId: json['enrollment_id'] as String,
      authenticatedAt: DateTime.parse(json['authenticated_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isAuthenticated: json['is_authenticated'] as bool,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      method: json['method'] as String,
    );
  }
}
