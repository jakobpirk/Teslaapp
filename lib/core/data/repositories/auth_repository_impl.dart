import 'package:dartz/dartz.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../exceptions/data_exceptions.dart';
import '../mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponseDto = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save token locally
      await localDataSource.saveToken(authResponseDto.token);

      return Right(AuthMapper.toAuthResponseEntity(authResponseDto));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final authResponseDto = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      // Save token locally
      await localDataSource.saveToken(authResponseDto.token);

      return Right(AuthMapper.toAuthResponseEntity(authResponseDto));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        await remoteDataSource.logout(token);
      }
      await localDataSource.clearToken();
      return const Right(null);
    } on ServerException catch (e) {
      // Even if server logout fails, clear local token
      await localDataSource.clearToken();
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      await localDataSource.clearToken();
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null) {
        return Left(UnauthorizedFailure());
      }

      final userDto = await remoteDataSource.getCurrentUser(token);
      return Right(AuthMapper.toUserEntity(userDto));
    } on UnauthorizedException {
      await localDataSource.clearToken();
      return Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword({
    required String email,
  }) async {
    try {
      final message = await remoteDataSource.forgotPassword(email: email);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      await remoteDataSource.verifyResetCode(email: email, code: code);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        email: email,
        code: code,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'An unexpected error occurred'));
    }
  }

  @override
  Future<String?> getStoredToken() async {
    return await localDataSource.getToken();
  }

  @override
  Future<void> saveToken(String token) async {
    await localDataSource.saveToken(token);
  }

  @override
  Future<void> clearToken() async {
    await localDataSource.clearToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await localDataSource.hasToken();
  }
}
