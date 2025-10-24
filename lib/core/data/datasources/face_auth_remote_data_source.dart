import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/face_enrollment_dto.dart';
import '../models/face_auth_response_dto.dart';
import '../exceptions/data_exceptions.dart';

/// Abstract interface for remote face authentication operations
abstract class FaceAuthRemoteDataSource {
  /// Verify face authentication with remote server
  Future<FaceAuthResponseDto> verifyAuthentication({
    required String userId,
    required String enrollmentId,
  });

  /// Register face enrollment with remote server
  Future<FaceEnrollmentDto> registerEnrollment({
    required String userId,
    String? deviceId,
  });

  /// Get enrollment from remote server
  Future<FaceEnrollmentDto> getEnrollment(String userId);

  /// Delete enrollment from remote server
  Future<void> deleteEnrollment(String userId);

  /// Verify session token with remote server
  Future<bool> verifySessionToken(String sessionToken);

  /// Invalidate session on remote server
  Future<void> invalidateSession(String sessionToken);
}

/// Implementation of remote face authentication data source
/// This uses both HTTP API and Firestore for demonstration
class FaceAuthRemoteDataSourceImpl implements FaceAuthRemoteDataSource {
  final http.Client httpClient;
  final FirebaseFirestore firestore;
  final String baseUrl;

  static const String _enrollmentsCollection = 'face_enrollments';
  static const String _sessionsCollection = 'face_auth_sessions';

  FaceAuthRemoteDataSourceImpl({
    required this.httpClient,
    required this.firestore,
    required this.baseUrl,
  });

  @override
  Future<FaceAuthResponseDto> verifyAuthentication({
    required String userId,
    required String enrollmentId,
  }) async {
    try {
      // In a real implementation, this would call an actual API endpoint
      // For this demo, we'll simulate a successful authentication

      // Store authentication session in Firestore
      final sessionRef = await firestore.collection(_sessionsCollection).add({
        'userId': userId,
        'enrollmentId': enrollmentId,
        'authenticatedAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'isAuthenticated': true,
        'confidenceScore': 0.95,
        'method': 'faceBiometric',
      });

      final sessionDoc = await sessionRef.get();
      final sessionData = sessionDoc.data()!;

      return FaceAuthResponseDto.fromFirestore(
        sessionData,
        sessionRef.id,
      );
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to verify authentication',
        e,
        'verifyAuthentication',
      );
    } catch (e) {
      throw FirestoreException(
        'Failed to verify authentication',
        e,
        'verifyAuthentication',
      );
    }
  }

  @override
  Future<FaceEnrollmentDto> registerEnrollment({
    required String userId,
    String? deviceId,
  }) async {
    try {
      // Check if enrollment already exists
      final existingEnrollments = await firestore
          .collection(_enrollmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // Delete existing enrollments if any
      for (var doc in existingEnrollments.docs) {
        await doc.reference.delete();
      }

      // Create new enrollment
      final enrollmentRef =
          await firestore.collection(_enrollmentsCollection).add({
        'userId': userId,
        'enrolledAt': Timestamp.now(),
        'isActive': true,
        'deviceId': deviceId,
        'biometricType': 'face',
      });

      final enrollmentDoc = await enrollmentRef.get();
      final enrollmentData = enrollmentDoc.data()!;

      return FaceEnrollmentDto.fromFirestore(
        enrollmentData,
        enrollmentRef.id,
      );
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to register enrollment',
        e,
        'registerEnrollment',
      );
    } catch (e) {
      throw FirestoreException(
        'Failed to register enrollment',
        e,
        'registerEnrollment',
      );
    }
  }

  @override
  Future<FaceEnrollmentDto> getEnrollment(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(_enrollmentsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw DataNotFoundException(
          'No active enrollment found for user',
          null,
          'FaceEnrollment',
          userId,
        );
      }

      final doc = querySnapshot.docs.first;
      return FaceEnrollmentDto.fromFirestore(doc.data(), doc.id);
    } on DataNotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to get enrollment',
        e,
        'getEnrollment',
      );
    } catch (e) {
      throw FirestoreException(
        'Failed to get enrollment',
        e,
        'getEnrollment',
      );
    }
  }

  @override
  Future<void> deleteEnrollment(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(_enrollmentsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Delete all enrollments for the user
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to delete enrollment',
        e,
        'deleteEnrollment',
      );
    } catch (e) {
      throw FirestoreException(
        'Failed to delete enrollment',
        e,
        'deleteEnrollment',
      );
    }
  }

  @override
  Future<bool> verifySessionToken(String sessionToken) async {
    try {
      final sessionDoc = await firestore
          .collection(_sessionsCollection)
          .doc(sessionToken)
          .get();

      if (!sessionDoc.exists) {
        return false;
      }

      final sessionData = sessionDoc.data()!;
      final expiresAt = (sessionData['expiresAt'] as Timestamp).toDate();

      // Check if session is expired
      if (DateTime.now().isAfter(expiresAt)) {
        return false;
      }

      return sessionData['isAuthenticated'] as bool? ?? false;
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to verify session token',
        e,
        'verifySessionToken',
      );
    } catch (e) {
      throw FirestoreException(
        'Failed to verify session token',
        e,
        'verifySessionToken',
      );
    }
  }

  @override
  Future<void> invalidateSession(String sessionToken) async {
    try {
      await firestore.collection(_sessionsCollection).doc(sessionToken).update({
        'isAuthenticated': false,
        'expiresAt': Timestamp.now(), // Expire immediately
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(
        'Failed to invalidate session',
        e,
        'invalidateSession',
      );
    } catch (e) {
      throw FirestoreException(
        'Failed to invalidate session',
        e,
        'invalidateSession',
      );
    }
  }
}
