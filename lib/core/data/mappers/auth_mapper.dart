import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';

class AuthMapper {
  static UserEntity toUserEntity(UserDto dto) {
    return UserEntity(
      id: dto.id,
      name: dto.name,
      email: dto.email,
    );
  }

  static UserDto toUserDto(UserEntity entity) {
    return UserDto(
      id: entity.id,
      name: entity.name,
      email: entity.email,
    );
  }

  static AuthResponseEntity toAuthResponseEntity(AuthResponseDto dto) {
    return AuthResponseEntity(
      user: toUserEntity(dto.user),
      token: dto.token,
    );
  }

  static AuthResponseDto toAuthResponseDto(AuthResponseEntity entity) {
    return AuthResponseDto(
      user: toUserDto(entity.user),
      token: entity.token,
    );
  }
}
