import 'package:dartz/dartz.dart';
import '../entities/auth_response_entity.dart';
import '../failures/failure.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await repository.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
