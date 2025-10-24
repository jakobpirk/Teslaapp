import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/backend_api_constants.dart';
import '../exceptions/data_exceptions.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';
import 'auth_remote_data_source.dart';

class AuthHttpDataSource implements AuthRemoteDataSource {
  final http.Client client;

  AuthHttpDataSource({required this.client});

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return AuthResponseDto.fromJson(jsonResponse);
        } else {
          throw ServerException(
            message: jsonResponse['message'] ?? 'Login failed',
          );
        }
      } else if (response.statusCode == 401) {
        throw ServerException(message: 'Invalid credentials');
      } else {
        throw ServerException(
          message: 'Failed to login: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResponseDto> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return AuthResponseDto.fromJson(jsonResponse);
        } else {
          throw ServerException(
            message: jsonResponse['message'] ?? 'Registration failed',
          );
        }
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(response.body);
        final errors = jsonResponse['errors'] as Map<String, dynamic>?;
        String errorMessage = 'Validation failed';
        if (errors != null) {
          errorMessage = errors.values.first[0].toString();
        }
        throw ServerException(message: errorMessage);
      } else {
        throw ServerException(
          message: 'Failed to register: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<void> logout(String token) async {
    try {
      final response = await client.post(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to logout: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<UserDto> getCurrentUser(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return UserDto.fromJson(jsonResponse['data']['user']);
        } else {
          throw ServerException(
            message: jsonResponse['message'] ?? 'Failed to get user',
          );
        }
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ServerException(
          message: 'Failed to get user: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await client.post(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // In development, the API returns the reset code
        // In production, this would just return a success message
        return jsonResponse['message'] ?? 'Reset code sent';
      } else {
        throw ServerException(
          message: 'Failed to send reset code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode != 200) {
        final jsonResponse = jsonDecode(response.body);
        throw ServerException(
          message: jsonResponse['message'] ?? 'Invalid reset code',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${BackendApiConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode != 200) {
        final jsonResponse = jsonDecode(response.body);
        throw ServerException(
          message: jsonResponse['message'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: $e');
    }
  }
}
