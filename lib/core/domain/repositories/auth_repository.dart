import 'package:dartz/dartz.dart';
import '../entities/auth_response_entity.dart';
import '../entities/user_entity.dart';
import '../failures/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, String>> forgotPassword({
    required String email,
  });

  Future<Either<Failure, void>> verifyResetCode({
    required String email,
    required String code,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  });

  Future<String?> getStoredToken();

  Future<void> saveToken(String token);

  Future<void> clearToken();

  Future<bool> isAuthenticated();
}
