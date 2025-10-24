import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/charging_session_dto.dart';

abstract class ChargingStatsRemoteDataSource {
  /// Get all charging sessions for a specific vehicle
  Future<List<ChargingSessionDto>> getChargingSessions(String vehicleId);

  /// Get charging sessions within a date range
  Future<List<ChargingSessionDto>> getChargingSessionsByDateRange(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get a specific charging session by ID
  Future<ChargingSessionDto> getChargingSession(String sessionId);

  /// Save a new charging session
  Future<void> saveChargingSession(
    String vehicleId,
    ChargingSessionDto session,
  );

  /// Update an existing charging session
  Future<void> updateChargingSession(ChargingSessionDto session);

  /// Delete a charging session
  Future<void> deleteChargingSession(String sessionId);

  /// Get the most recent charging session
  Future<ChargingSessionDto?> getMostRecentSession(String vehicleId);
}

class ChargingStatsRemoteDataSourceImpl
    implements ChargingStatsRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String _collectionName = 'charging_sessions';

  ChargingStatsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ChargingSessionDto>> getChargingSessions(
      String vehicleId) async {
    try {
      final querySnapshot = await firestore
          .collection(_collectionName)
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChargingSessionDto.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get charging sessions: $e');
    }
  }

  @override
  Future<List<ChargingSessionDto>> getChargingSessionsByDateRange(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await firestore
          .collection(_collectionName)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChargingSessionDto.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get charging sessions by date range: $e');
    }
  }

  @override
  Future<ChargingSessionDto> getChargingSession(String sessionId) async {
    try {
      final docSnapshot =
          await firestore.collection(_collectionName).doc(sessionId).get();

      if (!docSnapshot.exists) {
        throw Exception('Charging session not found: $sessionId');
      }

      return ChargingSessionDto.fromFirestore(
        docSnapshot.data()!,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Failed to get charging session: $e');
    }
  }

  @override
  Future<void> saveChargingSession(
    String vehicleId,
    ChargingSessionDto session,
  ) async {
    try {
      final data = session.toFirestore();
      data['vehicleId'] = vehicleId;

      await firestore.collection(_collectionName).doc(session.id).set(data);
    } catch (e) {
      throw Exception('Failed to save charging session: $e');
    }
  }

  @override
  Future<void> updateChargingSession(ChargingSessionDto session) async {
    try {
      await firestore
          .collection(_collectionName)
          .doc(session.id)
          .update(session.toFirestore());
    } catch (e) {
      throw Exception('Failed to update charging session: $e');
    }
  }

  @override
  Future<void> deleteChargingSession(String sessionId) async {
    try {
      await firestore.collection(_collectionName).doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete charging session: $e');
    }
  }

  @override
  Future<ChargingSessionDto?> getMostRecentSession(String vehicleId) async {
    try {
      final querySnapshot = await firestore
          .collection(_collectionName)
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ChargingSessionDto.fromFirestore(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to get most recent session: $e');
    }
  }
}
