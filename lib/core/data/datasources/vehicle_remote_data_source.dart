import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/api_constants.dart';
import '../models/vehicle_dto.dart';

/// Abstract interface for remote data source
abstract class VehicleRemoteDataSource {
  Future<VehicleDto> getVehicleState();
  Future<void> wakeVehicle();
  Future<void> lockVehicle();
  Future<void> unlockVehicle();
  Future<void> flashLights();
  Future<void> honkHorn();
  Future<void> startClimate();
  Future<void> stopClimate();
  Future<void> setTemperature(double temperature);
  Future<void> enableMaxDefrost();
  Future<void> disableMaxDefrost();
  Future<void> setSeatHeater(int seat, int level);
  Future<void> setSeatCooler(int seat, int level);
  Future<void> enableSteeringWheelHeater();
  Future<void> disableSteeringWheelHeater();
  Future<void> startCharging();
  Future<void> stopCharging();
  Future<void> setChargeLimit(int limit);
  Future<void> enableSentryMode();
  Future<void> disableSentryMode();
  Future<void> openFrunk();
  Future<void> openTrunk();
  Future<void> ventWindows();
  Future<void> closeWindows();
}

/// Implementation of remote data source using HTTP
class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final http.Client client;
  final String apiKey;
  final String vin;

  VehicleRemoteDataSourceImpl({
    required this.client,
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

  @override
  Future<VehicleDto> getVehicleState() async {
    final response = await client.get(
      Uri.parse(_buildUrl(ApiConstants.state)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return VehicleDto.fromJson(data);
    } else {
      throw Exception('Failed to load vehicle state: ${response.body}');
    }
  }

  @override
  Future<void> wakeVehicle() async {
    await _postRequest(ApiConstants.wake);
  }

  @override
  Future<void> lockVehicle() async {
    await _postRequest(ApiConstants.lock);
  }

  @override
  Future<void> unlockVehicle() async {
    await _postRequest(ApiConstants.unlock);
  }

  @override
  Future<void> flashLights() async {
    await _postRequest(ApiConstants.flash);
  }

  @override
  Future<void> honkHorn() async {
    await _postRequest(ApiConstants.honk);
  }

  @override
  Future<void> startClimate() async {
    await _postRequest(ApiConstants.startClimate);
  }

  @override
  Future<void> stopClimate() async {
    await _postRequest(ApiConstants.stopClimate);
  }

  @override
  Future<void> setTemperature(double temperature) async {
    await _postRequest(
      ApiConstants.setTemperature,
      body: {'temperature': temperature},
    );
  }

  @override
  Future<void> enableMaxDefrost() async {
    await _postRequest(ApiConstants.startDefrost);
  }

  @override
  Future<void> disableMaxDefrost() async {
    await _postRequest(ApiConstants.stopDefrost);
  }

  @override
  Future<void> setSeatHeater(int seat, int level) async {
    await _postRequest(
      ApiConstants.startSeatHeating,
      body: {'seat': seat, 'level': level},
    );
  }

  @override
  Future<void> setSeatCooler(int seat, int level) async {
    await _postRequest(
      ApiConstants.startSeatCooling,
      body: {'seat': seat, 'level': level},
    );
  }

  @override
  Future<void> enableSteeringWheelHeater() async {
    await _postRequest(ApiConstants.startSteeringWheelHeater);
  }

  @override
  Future<void> disableSteeringWheelHeater() async {
    await _postRequest(ApiConstants.stopSteeringWheelHeater);
  }

  @override
  Future<void> startCharging() async {
    await _postRequest(ApiConstants.startCharging);
  }

  @override
  Future<void> stopCharging() async {
    await _postRequest(ApiConstants.stopCharging);
  }

  @override
  Future<void> setChargeLimit(int limit) async {
    await _postRequest(
      ApiConstants.setChargeLimit,
      body: {'percent': limit},
    );
  }

  @override
  Future<void> enableSentryMode() async {
    await _postRequest(ApiConstants.enableSentryMode);
  }

  @override
  Future<void> disableSentryMode() async {
    await _postRequest(ApiConstants.disableSentryMode);
  }

  @override
  Future<void> openFrunk() async {
    await _postRequest(ApiConstants.openFrontTrunk);
  }

  @override
  Future<void> openTrunk() async {
    await _postRequest(ApiConstants.openRearTrunk);
  }

  @override
  Future<void> ventWindows() async {
    await _postRequest(ApiConstants.ventWindows);
  }

  @override
  Future<void> closeWindows() async {
    await _postRequest(ApiConstants.closeWindows);
  }

  /// Generic POST request handler
  Future<void> _postRequest(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await client.post(
      Uri.parse(_buildUrl(endpoint)),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Request failed: ${response.body}');
    }
  }
}
