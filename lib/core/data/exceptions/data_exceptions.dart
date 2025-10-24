/// Base exception class for all data layer exceptions
abstract class DataException implements Exception {
  final String message;
  final dynamic originalError;

  const DataException(this.message, [this.originalError]);

  @override
  String toString() => '$runtimeType: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}

/// Exception thrown when network operations fail
/// Use cases: HTTP request failures, connection timeouts, no internet
class NetworkException extends DataException {
  final int? statusCode;

  const NetworkException(
    super.message, [
    super.originalError,
    this.statusCode,
  ]);

  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Exception thrown when data parsing or serialization fails
/// Use cases: JSON decode errors, invalid data format, type conversion failures
class ParseException extends DataException {
  final String? fieldName;

  const ParseException(
    super.message, [
    super.originalError,
    this.fieldName,
  ]);

  @override
  String toString() => 'ParseException: $message${fieldName != null ? ' (Field: $fieldName)' : ''}';
}

/// Exception thrown when local storage operations fail
/// Use cases: Secure storage read/write errors, storage permission issues
class StorageException extends DataException {
  final String? key;

  const StorageException(
    super.message, [
    super.originalError,
    this.key,
  ]);

  @override
  String toString() => 'StorageException: $message${key != null ? ' (Key: $key)' : ''}';
}

/// Exception thrown when biometric authentication operations fail
/// Use cases: Biometric not available, authentication cancelled, hardware errors
class BiometricException extends DataException {
  final BiometricErrorType errorType;

  const BiometricException(
    super.message,
    this.errorType, [
    super.originalError,
  ]);

  @override
  String toString() => 'BiometricException: $message (Type: ${errorType.name})';
}

/// Types of biometric errors
enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  authenticationFailed,
  hardwareError,
  cancelled,
  lockout,
}

/// Exception thrown when requested data is not found
/// Use cases: Document not found in Firestore, user enrollment not found, session expired
class DataNotFoundException extends DataException {
  final String? resourceType;
  final String? resourceId;

  const DataNotFoundException(
    super.message, [
    super.originalError,
    this.resourceType,
    this.resourceId,
  ]);

  @override
  String toString() {
    final resource = resourceType != null && resourceId != null
        ? ' ($resourceType: $resourceId)'
        : resourceType != null
            ? ' (Type: $resourceType)'
            : '';
    return 'DataNotFoundException: $message$resource';
  }
}

/// Exception thrown when authentication or authorization fails
/// Use cases: Invalid credentials, expired tokens, permission denied
class AuthenticationException extends DataException {
  final int? statusCode;

  const AuthenticationException(
    super.message, [
    super.originalError,
    this.statusCode,
  ]);

  @override
  String toString() => 'AuthenticationException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Exception thrown when remote server operations fail
/// Use cases: 5xx errors, service unavailable, rate limiting
class ServerException extends DataException {
  final int? statusCode;

  const ServerException(
    super.message, [
    super.originalError,
    this.statusCode,
  ]);

  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Exception thrown when Firestore operations fail
/// Use cases: Permission denied, quota exceeded, Firestore connectivity issues
class FirestoreException extends DataException {
  final String? operation;

  const FirestoreException(
    super.message, [
    super.originalError,
    this.operation,
  ]);

  @override
  String toString() => 'FirestoreException: $message${operation != null ? ' (Operation: $operation)' : ''}';
}
