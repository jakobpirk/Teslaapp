import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:tessie_app/core/domain/entities/user_entity.dart';
import 'package:tessie_app/core/domain/entities/auth_response_entity.dart';
import 'package:tessie_app/core/domain/usecases/login_user.dart';
import 'package:tessie_app/core/domain/usecases/register_user.dart';
import 'package:tessie_app/core/domain/usecases/logout_user.dart';
import 'package:tessie_app/core/domain/usecases/forgot_password.dart';
import 'package:tessie_app/core/domain/usecases/reset_password.dart';
import 'package:tessie_app/core/domain/repositories/auth_repository.dart';
import 'package:tessie_app/core/domain/failures/failure.dart';
import 'package:tessie_app/features/auth/presentation/providers/auth_provider.dart';

@GenerateMocks([
  LoginUser,
  RegisterUser,
  LogoutUser,
  ForgotPassword,
  ResetPassword,
  AuthRepository,
])
import 'auth_provider_test.mocks.dart';

void main() {
  late AuthProvider authProvider;
  late MockLoginUser mockLoginUser;
  late MockRegisterUser mockRegisterUser;
  late MockLogoutUser mockLogoutUser;
  late MockForgotPassword mockForgotPassword;
  late MockResetPassword mockResetPassword;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockLoginUser = MockLoginUser();
    mockRegisterUser = MockRegisterUser();
    mockLogoutUser = MockLogoutUser();
    mockForgotPassword = MockForgotPassword();
    mockResetPassword = MockResetPassword();
    mockAuthRepository = MockAuthRepository();

    authProvider = AuthProvider(
      loginUseCase: mockLoginUser,
      registerUseCase: mockRegisterUser,
      logoutUseCase: mockLogoutUser,
      forgotPasswordUseCase: mockForgotPassword,
      resetPasswordUseCase: mockResetPassword,
      authRepository: mockAuthRepository,
    );
  });

  const tUser = UserEntity(
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
  );

  const tAuthResponse = AuthResponseEntity(
    user: tUser,
    token: 'test_token',
  );

  group('login', () {
    test('should update state correctly on successful login', () async {
      when(mockLoginUser(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Right(tAuthResponse));

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, null);

      await authProvider.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, tUser);
      expect(authProvider.error, null);
      expect(authProvider.isLoading, false);
    });

    test('should update state with error on failed login', () async {
      when(mockLoginUser(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Left(ServerFailure(message: 'Invalid credentials')));

      await authProvider.login(
        email: 'test@example.com',
        password: 'wrong_password',
      );

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, null);
      expect(authProvider.error, 'Invalid credentials');
      expect(authProvider.isLoading, false);
    });
  });

  group('register', () {
    test('should update state correctly on successful registration', () async {
      when(mockRegisterUser(
        name: anyNamed('name'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        passwordConfirmation: anyNamed('passwordConfirmation'),
      )).thenAnswer((_) async => const Right(tAuthResponse));

      await authProvider.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, tUser);
      expect(authProvider.error, null);
    });

    test('should update state with error on failed registration', () async {
      when(mockRegisterUser(
        name: anyNamed('name'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        passwordConfirmation: anyNamed('passwordConfirmation'),
      )).thenAnswer((_) async => Left(ServerFailure(message: 'Email already exists')));

      await authProvider.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.error, 'Email already exists');
    });
  });

  group('logout', () {
    test('should clear user state on logout', () async {
      // First login
      when(mockLoginUser(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Right(tAuthResponse));

      await authProvider.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);

      // Then logout
      when(mockLogoutUser()).thenAnswer((_) async => const Right(null));

      await authProvider.logout();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, null);
    });
  });

  group('forgot password', () {
    test('should clear error on successful forgot password', () async {
      when(mockForgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async => const Right('Reset code sent'));

      await authProvider.forgotPassword(email: 'test@example.com');

      expect(authProvider.error, null);
      expect(authProvider.isLoading, false);
    });

    test('should set error on failed forgot password', () async {
      when(mockForgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async => Left(ServerFailure(message: 'Email not found')));

      await authProvider.forgotPassword(email: 'test@example.com');

      expect(authProvider.error, 'Email not found');
    });
  });
}
