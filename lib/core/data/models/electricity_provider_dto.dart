import 'package:json_annotation/json_annotation.dart';

part 'electricity_provider_dto.g.dart';

@JsonSerializable()
class ElectricityProviderDto {
  final String id;
  final String name;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'api_base_url')
  final String apiBaseUrl;
  final String? description;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'pricing_structure')
  final Map<String, dynamic>? pricingStructure;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ElectricityProviderDto({
    required this.id,
    required this.name,
    required this.displayName,
    required this.apiBaseUrl,
    this.description,
    this.isActive = true,
    this.pricingStructure,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ElectricityProviderDto.fromJson(Map<String, dynamic> json) =>
      _$ElectricityProviderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ElectricityProviderDtoToJson(this);

  List<String> get rateTypes {
    if (pricingStructure == null) return [];
    final rates = pricingStructure!['rate_types'];
    if (rates is List) {
      return rates.cast<String>();
    }
    return [];
  }
}
