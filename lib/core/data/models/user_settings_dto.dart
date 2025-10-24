import 'package:json_annotation/json_annotation.dart';
import 'electricity_provider_dto.dart';

part 'user_settings_dto.g.dart';

@JsonSerializable()
class UserSettingsDto {
  @JsonKey(name: 'has_tessie_api_key')
  final bool hasTessieApiKey;
  @JsonKey(name: 'electricity_provider')
  final ElectricityProviderDto? electricityProvider;

  UserSettingsDto({
    required this.hasTessieApiKey,
    this.electricityProvider,
  });

  factory UserSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsDtoToJson(this);
}

@JsonSerializable()
class UserProfileDto {
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'has_tessie_api_key')
  final bool hasTessieApiKey;
  @JsonKey(name: 'electricity_provider')
  final ElectricityProviderDto? electricityProvider;
  @JsonKey(name: 'vehicles_count')
  final int vehiclesCount;
  @JsonKey(name: 'active_vehicles_count')
  final int activeVehiclesCount;

  UserProfileDto({
    required this.id,
    required this.name,
    required this.email,
    required this.hasTessieApiKey,
    this.electricityProvider,
    required this.vehiclesCount,
    required this.activeVehiclesCount,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}
