import 'package:flutter/foundation.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../../core/domain/usecases/login_user.dart';
import '../../../../core/domain/usecases/register_user.dart';
import '../../../../core/domain/usecases/logout_user.dart';
import '../../../../core/domain/usecases/forgot_password.dart';
import '../../../../core/domain/usecases/reset_password.dart';
import '../../../../core/domain/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final LoginUser loginUseCase;
  final RegisterUser registerUseCase;
  final LogoutUser logoutUseCase;
  final ForgotPassword forgotPasswordUseCase;
  final ResetPassword resetPasswordUseCase;
  final AuthRepository authRepository;

  AuthProvider({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.authRepository,
  });

  UserEntity? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize auth state on app start
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    final hasToken = await authRepository.isAuthenticated();
    if (hasToken) {
      final result = await authRepository.getCurrentUser();
      result.fold(
        (failure) {
          _isAuthenticated = false;
          _user = null;
        },
        (user) {
          _isAuthenticated = true;
          _user = user;
        },
      );
    } else {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await loginUseCase(
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
      },
      (authResponse) {
        _user = authResponse.user;
        _isAuthenticated = true;
        _error = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Register
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await registerUseCase(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
      },
      (authResponse) {
        _user = authResponse.user;
        _isAuthenticated = true;
        _error = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await logoutUseCase();

    _user = null;
    _isAuthenticated = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Forgot Password
  Future<void> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await forgotPasswordUseCase(email: email);

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (message) {
        _error = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Reset Password
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await resetPasswordUseCase(
      email: email,
      code: code,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _error = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
