import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await repository.resetPassword(
      email: email,
      code: code,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
