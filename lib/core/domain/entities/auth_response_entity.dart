import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthResponseEntity extends Equatable {
  final UserEntity user;
  final String token;

  const AuthResponseEntity({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];

  @override
  String toString() => 'AuthResponseEntity(user: $user, token: $token)';
}
