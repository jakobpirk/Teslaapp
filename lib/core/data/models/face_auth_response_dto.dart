import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Transfer Object for Face Authentication Response
/// Used for serialization/deserialization between data sources
class FaceAuthResponseDto {
  final bool isAuthenticated;
  final String userId;
  final String sessionToken;
  final Timestamp authenticatedAt;
  final Timestamp expiresAt;
  final double confidenceScore;
  final String? enrollmentId;
  final String method;

  const FaceAuthResponseDto({
    required this.isAuthenticated,
    required this.userId,
    required this.sessionToken,
    required this.authenticatedAt,
    required this.expiresAt,
    required this.confidenceScore,
    this.enrollmentId,
    required this.method,
  });

  /// Create DTO from JSON map (API response)
  factory FaceAuthResponseDto.fromJson(Map<String, dynamic> json) {
    return FaceAuthResponseDto(
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      userId: json['userId'] as String? ?? '',
      sessionToken: json['sessionToken'] as String? ?? '',
      authenticatedAt: json['authenticatedAt'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['authenticatedAt'] as int)
          : Timestamp.fromDate(DateTime.now()),
      expiresAt: json['expiresAt'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      enrollmentId: json['enrollmentId'] as String?,
      method: json['method'] as String? ?? 'faceBiometric',
    );
  }

  /// Create DTO from Firestore document
  factory FaceAuthResponseDto.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return FaceAuthResponseDto(
      isAuthenticated: data['isAuthenticated'] as bool? ?? false,
      userId: data['userId'] as String? ?? '',
      sessionToken: id,
      authenticatedAt: data['authenticatedAt'] as Timestamp? ??
          Timestamp.fromDate(DateTime.now()),
      expiresAt: data['expiresAt'] as Timestamp? ??
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      enrollmentId: data['enrollmentId'] as String?,
      method: data['method'] as String? ?? 'faceBiometric',
    );
  }

  /// Convert DTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'isAuthenticated': isAuthenticated,
      'userId': userId,
      'sessionToken': sessionToken,
      'authenticatedAt': authenticatedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'confidenceScore': confidenceScore,
      'enrollmentId': enrollmentId,
      'method': method,
    };
  }

  /// Convert DTO to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'isAuthenticated': isAuthenticated,
      'userId': userId,
      'authenticatedAt': authenticatedAt,
      'expiresAt': expiresAt,
      'confidenceScore': confidenceScore,
      'enrollmentId': enrollmentId,
      'method': method,
    };
  }

  /// Create a copy with modified fields
  FaceAuthResponseDto copyWith({
    bool? isAuthenticated,
    String? userId,
    String? sessionToken,
    Timestamp? authenticatedAt,
    Timestamp? expiresAt,
    double? confidenceScore,
    String? enrollmentId,
    String? method,
  }) {
    return FaceAuthResponseDto(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      sessionToken: sessionToken ?? this.sessionToken,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      method: method ?? this.method,
    );
  }
}
