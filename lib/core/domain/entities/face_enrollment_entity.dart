/// Entity representing a face enrollment/registration
class FaceEnrollmentEntity {
  final String userId;
  final String enrollmentId;
  final DateTime enrolledAt;
  final bool isActive;
  final String? deviceId;
  final BiometricTypeEntity biometricType;

  const FaceEnrollmentEntity({
    required this.userId,
    required this.enrollmentId,
    required this.enrolledAt,
    required this.isActive,
    this.deviceId,
    required this.biometricType,
  });

  FaceEnrollmentEntity copyWith({
    String? userId,
    String? enrollmentId,
    DateTime? enrolledAt,
    bool? isActive,
    String? deviceId,
    BiometricTypeEntity? biometricType,
  }) {
    return FaceEnrollmentEntity(
      userId: userId ?? this.userId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
      biometricType: biometricType ?? this.biometricType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceEnrollmentEntity &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          enrollmentId == other.enrollmentId &&
          enrolledAt == other.enrolledAt &&
          isActive == other.isActive &&
          deviceId == other.deviceId &&
          biometricType == other.biometricType;

  @override
  int get hashCode =>
      userId.hashCode ^
      enrollmentId.hashCode ^
      enrolledAt.hashCode ^
      isActive.hashCode ^
      deviceId.hashCode ^
      biometricType.hashCode;
}

/// Biometric type enumeration
enum BiometricTypeEntity {
  face,
  fingerprint,
  iris,
  voice;

  String get displayName {
    switch (this) {
      case BiometricTypeEntity.face:
        return 'Face Recognition';
      case BiometricTypeEntity.fingerprint:
        return 'Fingerprint';
      case BiometricTypeEntity.iris:
        return 'Iris Scan';
      case BiometricTypeEntity.voice:
        return 'Voice Recognition';
    }
  }
}
