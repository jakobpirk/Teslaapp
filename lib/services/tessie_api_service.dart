import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/vehicle_state.dart';

class TessieApiService {
  final String apiKey;
  final String vin;

  TessieApiService({
    required this.apiKey,
    required this.vin,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  String _buildUrl(String endpoint) {
    return '${ApiConstants.baseUrl}/$vin$endpoint';
  }

  // Get Vehicle State
  Future<VehicleState> getVehicleState() async {
    final response = await http.get(
      Uri.parse(_buildUrl(ApiConstants.state)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VehicleState.fromJson(data);
    } else {
      throw Exception('Failed to load vehicle state: ${response.body}');
    }
  }

  // Wake Vehicle
  Future<Map<String, dynamic>> wakeVehicle() async {
    return _postRequest(ApiConstants.wake);
  }

  // Lock Controls
  Future<Map<String, dynamic>> lockVehicle() async {
    return _postRequest(ApiConstants.lock);
  }

  Future<Map<String, dynamic>> unlockVehicle() async {
    return _postRequest(ApiConstants.unlock);
  }

  // Climate Controls
  Future<Map<String, dynamic>> startClimate() async {
    return _postRequest(ApiConstants.startClimate);
  }

  Future<Map<String, dynamic>> stopClimate() async {
    return _postRequest(ApiConstants.stopClimate);
  }

  Future<Map<String, dynamic>> setTemperature(double temp) async {
    return _postRequest(
      ApiConstants.setTemperature,
      body: {'temperature': temp},
    );
  }

  Future<Map<String, dynamic>> startDefrost() async {
    return _postRequest(ApiConstants.startDefrost);
  }

  Future<Map<String, dynamic>> stopDefrost() async {
    return _postRequest(ApiConstants.stopDefrost);
  }

  Future<Map<String, dynamic>> startSeatHeating(int seat, int level) async {
    return _postRequest(
      ApiConstants.startSeatHeating,
      body: {'seat': seat, 'level': level},
    );
  }

  Future<Map<String, dynamic>> startSeatCooling(int seat, int level) async {
    return _postRequest(
      ApiConstants.startSeatCooling,
      body: {'seat': seat, 'level': level},
    );
  }

  Future<Map<String, dynamic>> startSteeringWheelHeater() async {
    return _postRequest(ApiConstants.startSteeringWheelHeater);
  }

  Future<Map<String, dynamic>> stopSteeringWheelHeater() async {
    return _postRequest(ApiConstants.stopSteeringWheelHeater);
  }

  // Charging Controls
  Future<Map<String, dynamic>> startCharging() async {
    return _postRequest(ApiConstants.startCharging);
  }

  Future<Map<String, dynamic>> stopCharging() async {
    return _postRequest(ApiConstants.stopCharging);
  }

  Future<Map<String, dynamic>> setChargeLimit(int percent) async {
    return _postRequest(
      ApiConstants.setChargeLimit,
      body: {'percent': percent},
    );
  }

  // Vehicle Actions
  Future<Map<String, dynamic>> flashLights() async {
    return _postRequest(ApiConstants.flash);
  }

  Future<Map<String, dynamic>> honkHorn() async {
    return _postRequest(ApiConstants.honk);
  }

  Future<Map<String, dynamic>> enableSentryMode() async {
    return _postRequest(ApiConstants.enableSentryMode);
  }

  Future<Map<String, dynamic>> disableSentryMode() async {
    return _postRequest(ApiConstants.disableSentryMode);
  }

  Future<Map<String, dynamic>> openFrunk() async {
    return _postRequest(ApiConstants.openFrontTrunk);
  }

  Future<Map<String, dynamic>> openTrunk() async {
    return _postRequest(ApiConstants.openRearTrunk);
  }

  // Windows
  Future<Map<String, dynamic>> ventWindows() async {
    return _postRequest(ApiConstants.ventWindows);
  }

  Future<Map<String, dynamic>> closeWindows() async {
    return _postRequest(ApiConstants.closeWindows);
  }

  // Generic POST request
  Future<Map<String, dynamic>> _postRequest(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      Uri.parse(_buildUrl(endpoint)),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Request failed: ${response.body}');
    }
  }
}
