import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data layer
import '../data/datasources/vehicle_remote_data_source.dart';
import '../data/repositories/vehicle_repository_impl.dart';
import '../data/datasources/charging_stats_remote_datasource.dart';
import '../data/repositories/charging_stats_repository_impl.dart';

// Domain layer
import '../domain/repositories/vehicle_repository.dart';
import '../domain/repositories/charging_stats_repository.dart';
import '../domain/usecases/get_vehicle_state.dart';
import '../domain/usecases/wake_vehicle.dart';
import '../domain/usecases/vehicle_lock_operations.dart';
import '../domain/usecases/vehicle_alert_operations.dart';
import '../domain/usecases/climate_operations.dart';
import '../domain/usecases/charging_operations.dart';
import '../domain/usecases/security_operations.dart';
import '../domain/usecases/vehicle_access_operations.dart';
import '../domain/usecases/get_charging_sessions.dart';
import '../domain/usecases/save_charging_session.dart';

// Presentation layer
import '../../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../../features/charging_stats/presentation/providers/charging_stats_provider.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External dependencies
  sl.registerLazySingleton(() => http.Client());

  // Data sources
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(
      client: sl(),
      apiKey: dotenv.env['TESSIE_API_KEY'] ?? '',
      vin: dotenv.env['TESSIE_VIN'] ?? '',
    ),
  );

  // Repository
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetVehicleState(sl()));
  sl.registerLazySingleton(() => WakeVehicle(sl()));
  sl.registerLazySingleton(() => LockVehicle(sl()));
  sl.registerLazySingleton(() => UnlockVehicle(sl()));
  sl.registerLazySingleton(() => FlashLights(sl()));
  sl.registerLazySingleton(() => HonkHorn(sl()));
  sl.registerLazySingleton(() => StartClimate(sl()));
  sl.registerLazySingleton(() => StopClimate(sl()));
  sl.registerLazySingleton(() => SetTemperature(sl()));
  sl.registerLazySingleton(() => EnableMaxDefrost(sl()));
  sl.registerLazySingleton(() => DisableMaxDefrost(sl()));
  sl.registerLazySingleton(() => SetSeatHeater(sl()));
  sl.registerLazySingleton(() => SetSeatCooler(sl()));
  sl.registerLazySingleton(() => EnableSteeringWheelHeater(sl()));
  sl.registerLazySingleton(() => DisableSteeringWheelHeater(sl()));
  sl.registerLazySingleton(() => StartCharging(sl()));
  sl.registerLazySingleton(() => StopCharging(sl()));
  sl.registerLazySingleton(() => SetChargeLimit(sl()));
  sl.registerLazySingleton(() => EnableSentryMode(sl()));
  sl.registerLazySingleton(() => DisableSentryMode(sl()));
  sl.registerLazySingleton(() => OpenFrunk(sl()));
  sl.registerLazySingleton(() => OpenTrunk(sl()));
  sl.registerLazySingleton(() => VentWindows(sl()));
  sl.registerLazySingleton(() => CloseWindows(sl()));

  // Providers
  sl.registerFactory(
    () => VehicleProvider(
      getVehicleState: sl(),
      wakeVehicle: sl(),
      lockVehicle: sl(),
      unlockVehicle: sl(),
      flashLights: sl(),
      honkHorn: sl(),
      startClimate: sl(),
      stopClimate: sl(),
      setTemperature: sl(),
      enableMaxDefrost: sl(),
      disableMaxDefrost: sl(),
      setSeatHeater: sl(),
      setSeatCooler: sl(),
      enableSteeringWheelHeater: sl(),
      disableSteeringWheelHeater: sl(),
      startCharging: sl(),
      stopCharging: sl(),
      setChargeLimit: sl(),
      enableSentryMode: sl(),
      disableSentryMode: sl(),
      openFrunk: sl(),
      openTrunk: sl(),
      ventWindows: sl(),
      closeWindows: sl(),
    ),
  );

  // Charging Stats - Firestore
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Charging Stats - Data sources
  sl.registerLazySingleton<ChargingStatsRemoteDataSource>(
    () => ChargingStatsRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  // Charging Stats - Repository
  sl.registerLazySingleton<ChargingStatsRepository>(
    () => ChargingStatsRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Charging Stats - Use cases
  sl.registerLazySingleton(() => GetChargingSessions(sl()));
  sl.registerLazySingleton(() => SaveChargingSession(sl()));

  // Charging Stats - Provider
  sl.registerFactory(
    () => ChargingStatsProvider(
      getChargingSessions: sl(),
      saveChargingSession: sl(),
    ),
  );
}
