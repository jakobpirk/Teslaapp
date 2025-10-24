import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Transfer Object for Face Enrollment
/// Used for serialization/deserialization between data sources
class FaceEnrollmentDto {
  final String userId;
  final String enrollmentId;
  final Timestamp enrolledAt;
  final bool isActive;
  final String? deviceId;
  final String biometricType;

  const FaceEnrollmentDto({
    required this.userId,
    required this.enrollmentId,
    required this.enrolledAt,
    required this.isActive,
    this.deviceId,
    required this.biometricType,
  });

  /// Create DTO from Firestore document
  factory FaceEnrollmentDto.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return FaceEnrollmentDto(
      userId: data['userId'] as String? ?? '',
      enrollmentId: id,
      enrolledAt: data['enrolledAt'] as Timestamp? ??
          Timestamp.fromDate(DateTime.now()),
      isActive: data['isActive'] as bool? ?? true,
      deviceId: data['deviceId'] as String?,
      biometricType: data['biometricType'] as String? ?? 'face',
    );
  }

  /// Create DTO from JSON map
  factory FaceEnrollmentDto.fromJson(Map<String, dynamic> json) {
    return FaceEnrollmentDto(
      userId: json['userId'] as String? ?? '',
      enrollmentId: json['enrollmentId'] as String? ?? '',
      enrolledAt: json['enrolledAt'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['enrolledAt'] as int)
          : Timestamp.fromDate(DateTime.now()),
      isActive: json['isActive'] as bool? ?? true,
      deviceId: json['deviceId'] as String?,
      biometricType: json['biometricType'] as String? ?? 'face',
    );
  }

  /// Convert DTO to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'enrolledAt': enrolledAt,
      'isActive': isActive,
      'deviceId': deviceId,
      'biometricType': biometricType,
    };
  }

  /// Convert DTO to JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enrollmentId': enrollmentId,
      'enrolledAt': enrolledAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'deviceId': deviceId,
      'biometricType': biometricType,
    };
  }

  /// Create a copy with modified fields
  FaceEnrollmentDto copyWith({
    String? userId,
    String? enrollmentId,
    Timestamp? enrolledAt,
    bool? isActive,
    String? deviceId,
    String? biometricType,
  }) {
    return FaceEnrollmentDto(
      userId: userId ?? this.userId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
      biometricType: biometricType ?? this.biometricType,
    );
  }
}
