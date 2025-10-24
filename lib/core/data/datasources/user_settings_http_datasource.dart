import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_settings_dto.dart';

class UserSettingsHttpDataSource {
  final http.Client client;
  final String baseUrl;

  UserSettingsHttpDataSource({
    required this.client,
    this.baseUrl = 'http://localhost:8000/api/v1',
  });

  /// Get user settings
  Future<UserSettingsDto> getSettings(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/user/settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserSettingsDto.fromJson(data['data']);
    } else {
      throw Exception('Failed to load settings: ${response.body}');
    }
  }

  /// Get user profile with settings
  Future<UserProfileDto> getProfile(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserProfileDto.fromJson(data['data']);
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  /// Update Tessie API key
  Future<void> updateTessieApiKey(String token, String apiKey) async {
    final response = await client.post(
      Uri.parse('$baseUrl/user/settings/tessie-api-key'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'tessie_api_key': apiKey}),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to update Tessie API key');
    }
  }

  /// Remove Tessie API key
  Future<void> removeTessieApiKey(String token) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/user/settings/tessie-api-key'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove Tessie API key');
    }
  }

  /// Update electricity provider
  Future<void> updateElectricityProvider(
    String token,
    String providerId,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/user/settings/electricity-provider'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'electricity_provider_id': providerId}),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to update electricity provider');
    }
  }
}
