/// Entity representing a face authentication response
class FaceAuthResponseEntity {
  final bool isAuthenticated;
  final String userId;
  final String sessionToken;
  final DateTime authenticatedAt;
  final DateTime expiresAt;
  final double confidenceScore; // 0.0 to 1.0
  final String? enrollmentId;
  final AuthenticationMethodEntity method;

  const FaceAuthResponseEntity({
    required this.isAuthenticated,
    required this.userId,
    required this.sessionToken,
    required this.authenticatedAt,
    required this.expiresAt,
    required this.confidenceScore,
    this.enrollmentId,
    required this.method,
  });

  /// Check if the authentication session is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Get the remaining time before session expiration in minutes
  int get remainingMinutes {
    if (!isValid) return 0;
    return expiresAt.difference(DateTime.now()).inMinutes;
  }

  /// Check if the confidence score meets the minimum threshold
  bool meetsConfidenceThreshold(double threshold) {
    return confidenceScore >= threshold;
  }

  FaceAuthResponseEntity copyWith({
    bool? isAuthenticated,
    String? userId,
    String? sessionToken,
    DateTime? authenticatedAt,
    DateTime? expiresAt,
    double? confidenceScore,
    String? enrollmentId,
    AuthenticationMethodEntity? method,
  }) {
    return FaceAuthResponseEntity(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceAuthResponseEntity &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          userId == other.userId &&
          sessionToken == other.sessionToken &&
          authenticatedAt == other.authenticatedAt &&
          expiresAt == other.expiresAt &&
          confidenceScore == other.confidenceScore &&
          enrollmentId == other.enrollmentId &&
          method == other.method;

  @override
  int get hashCode =>
      isAuthenticated.hashCode ^
      userId.hashCode ^
      sessionToken.hashCode ^
      authenticatedAt.hashCode ^
      expiresAt.hashCode ^
      confidenceScore.hashCode ^
      enrollmentId.hashCode ^
      method.hashCode;
}

/// Authentication method enumeration
enum AuthenticationMethodEntity {
  faceBiometric,
  faceWithLiveness,
  faceWithPin,
  fallbackPassword;

  String get displayName {
    switch (this) {
      case AuthenticationMethodEntity.faceBiometric:
        return 'Face Biometric';
      case AuthenticationMethodEntity.faceWithLiveness:
        return 'Face with Liveness Detection';
      case AuthenticationMethodEntity.faceWithPin:
        return 'Face with PIN';
      case AuthenticationMethodEntity.fallbackPassword:
        return 'Password (Fallback)';
    }
  }

  bool get isFaceBased {
    switch (this) {
      case AuthenticationMethodEntity.faceBiometric:
      case AuthenticationMethodEntity.faceWithLiveness:
      case AuthenticationMethodEntity.faceWithPin:
        return true;
      case AuthenticationMethodEntity.fallbackPassword:
        return false;
    }
  }
}
