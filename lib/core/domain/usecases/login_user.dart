import 'package:dartz/dartz.dart';
import '../entities/auth_response_entity.dart';
import '../failures/failure.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(email: email, password: password);
  }
}
