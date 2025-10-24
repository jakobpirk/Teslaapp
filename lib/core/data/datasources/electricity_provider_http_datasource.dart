import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/electricity_provider_dto.dart';

class ElectricityProviderHttpDataSource {
  final http.Client client;
  final String baseUrl;

  ElectricityProviderHttpDataSource({
    required this.client,
    this.baseUrl = 'http://localhost:8000/api/v1',
  });

  /// Get all active electricity providers
  Future<List<ElectricityProviderDto>> getProviders() async {
    final response = await client.get(
      Uri.parse('$baseUrl/electricity-providers'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final providers = (data['data'] as List)
          .map((json) => ElectricityProviderDto.fromJson(json))
          .toList();
      return providers;
    } else {
      throw Exception('Failed to load providers: ${response.body}');
    }
  }

  /// Get providers by country
  Future<List<ElectricityProviderDto>> getProvidersByCountry(
    String country,
  ) async {
    final response = await client.get(
      Uri.parse('$baseUrl/electricity-providers/country/$country'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final providers = (data['data'] as List)
          .map((json) => ElectricityProviderDto.fromJson(json))
          .toList();
      return providers;
    } else {
      throw Exception('Failed to load providers by country: ${response.body}');
    }
  }

  /// Get a specific provider
  Future<ElectricityProviderDto> getProvider(String providerId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/electricity-providers/$providerId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ElectricityProviderDto.fromJson(data['data']);
    } else {
      throw Exception('Failed to load provider: ${response.body}');
    }
  }

  /// Get current pricing for a provider
  Future<Map<String, dynamic>> getCurrentPricing(
    String providerId, {
    String? location,
  }) async {
    final uri = Uri.parse('$baseUrl/electricity-providers/$providerId/pricing/current')
        .replace(queryParameters: location != null ? {'location': location} : null);

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load current pricing: ${response.body}');
    }
  }

  /// Get pricing forecast for a provider
  Future<List<Map<String, dynamic>>> getPricingForecast(
    String providerId, {
    int hours = 48,
    String? location,
  }) async {
    final queryParams = <String, String>{
      'hours': hours.toString(),
    };
    if (location != null) {
      queryParams['location'] = location;
    }

    final uri = Uri.parse('$baseUrl/electricity-providers/$providerId/pricing/forecast')
        .replace(queryParameters: queryParams);

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load pricing forecast: ${response.body}');
    }
  }

  /// Update pricing data (requires authentication)
  Future<void> updatePricing(
    String token,
    String providerId, {
    String? location,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/electricity-providers/$providerId/pricing/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'location': location}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update pricing: ${response.body}');
    }
  }
}
