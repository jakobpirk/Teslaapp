import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  });

  Future<AuthResponseDto> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<void> logout(String token);

  Future<UserDto> getCurrentUser(String token);

  Future<String> forgotPassword({
    required String email,
  });

  Future<void> verifyResetCode({
    required String email,
    required String code,
  });

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  });
}
