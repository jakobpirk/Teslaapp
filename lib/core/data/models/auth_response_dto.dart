import 'package:equatable/equatable.dart';
import 'user_dto.dart';

class AuthResponseDto extends Equatable {
  final UserDto user;
  final String token;

  const AuthResponseDto({
    required this.user,
    required this.token,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponseDto(
      user: UserDto.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'user': user.toJson(),
        'token': token,
      },
    };
  }

  @override
  List<Object?> get props => [user, token];
}
