import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../repositories/auth_repository.dart';

class ForgotPassword {
  final AuthRepository repository;

  ForgotPassword(this.repository);

  Future<Either<Failure, String>> call({required String email}) async {
    return await repository.forgotPassword(email: email);
  }
}
