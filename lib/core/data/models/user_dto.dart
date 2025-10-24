import 'package:equatable/equatable.dart';

class UserDto extends Equatable {
  final int id;
  final String name;
  final String email;

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [id, name, email];
}
