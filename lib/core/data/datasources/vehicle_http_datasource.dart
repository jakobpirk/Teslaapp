import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_model_dto.dart';

class VehicleHttpDataSource {
  final http.Client client;
  final String baseUrl;

  VehicleHttpDataSource({
    required this.client,
    this.baseUrl = 'http://localhost:8000/api/v1',
  });

  /// Get all vehicles for the authenticated user
  Future<List<VehicleModelDto>> getVehicles(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final vehicles = (data['data'] as List)
          .map((json) => VehicleModelDto.fromJson(json))
          .toList();
      return vehicles;
    } else {
      throw Exception('Failed to load vehicles: ${response.body}');
    }
  }

  /// Get only active vehicles
  Future<List<VehicleModelDto>> getActiveVehicles(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/vehicles/active'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final vehicles = (data['data'] as List)
          .map((json) => VehicleModelDto.fromJson(json))
          .toList();
      return vehicles;
    } else {
      throw Exception('Failed to load active vehicles: ${response.body}');
    }
  }

  /// Get a specific vehicle
  Future<VehicleModelDto> getVehicle(String token, String vehicleId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VehicleModelDto.fromJson(data['data']);
    } else {
      throw Exception('Failed to load vehicle: ${response.body}');
    }
  }

  /// Create a new vehicle
  Future<VehicleModelDto> createVehicle(
    String token,
    CreateVehicleDto vehicleDto,
  ) async {
    final response = await client.post(
      Uri.parse('$baseUrl/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(vehicleDto.toJson()),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return VehicleModelDto.fromJson(data['data']);
    } else {
      throw Exception('Failed to create vehicle: ${response.body}');
    }
  }

  /// Update a vehicle
  Future<VehicleModelDto> updateVehicle(
    String token,
    String vehicleId,
    UpdateVehicleDto vehicleDto,
  ) async {
    final response = await client.put(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(vehicleDto.toJson()),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VehicleModelDto.fromJson(data['data']);
    } else {
      throw Exception('Failed to update vehicle: ${response.body}');
    }
  }

  /// Delete (deactivate) a vehicle
  Future<void> deleteVehicle(String token, String vehicleId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/vehicles/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete vehicle: ${response.body}');
    }
  }

  /// Get vehicle statistics
  Future<Map<String, dynamic>> getVehicleStatistics(
    String token,
    String vehicleId,
  ) async {
    final response = await client.get(
      Uri.parse('$baseUrl/vehicles/$vehicleId/statistics'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load vehicle statistics: ${response.body}');
    }
  }
}
