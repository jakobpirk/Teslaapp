import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Data layer
import '../data/datasources/vehicle_remote_data_source.dart';
import '../data/repositories/vehicle_repository_impl.dart';
import '../data/datasources/charging_stats_http_datasource.dart';
import '../data/repositories/charging_stats_repository_impl.dart';
import '../data/datasources/face_auth_local_data_source.dart';
import '../data/datasources/face_auth_http_data_source.dart';
import '../data/repositories/face_auth_repository_impl.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/datasources/auth_http_data_source.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../data/datasources/auth_secure_storage_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';

// Domain layer
import '../domain/repositories/vehicle_repository.dart';
import '../domain/repositories/charging_stats_repository.dart';
import '../domain/repositories/face_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
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
import '../domain/usecases/authenticate_with_face.dart';
import '../domain/usecases/enroll_face_biometric.dart';
import '../domain/usecases/login_user.dart';
import '../domain/usecases/register_user.dart';
import '../domain/usecases/logout_user.dart';
import '../domain/usecases/forgot_password.dart';
import '../domain/usecases/reset_password.dart';

// Presentation layer
import '../../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../../features/charging_stats/presentation/providers/charging_stats_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External dependencies
  sl.registerLazySingleton(() => http.Client());

  // Configure Dio for HTTP requests to backend
  sl.registerLazySingleton(() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  });

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

  // Charging Stats - Data sources (using HTTP instead of Firestore)
  sl.registerLazySingleton<ChargingStatsHttpDataSource>(
    () => ChargingStatsHttpDataSource(
      dio: sl(),
      baseUrl: dotenv.env['BACKEND_API_URL'] ?? 'http://localhost:8080',
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

  // Face Authentication - External dependencies
  sl.registerLazySingleton(() => LocalAuthentication());
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Face Authentication - Data sources
  sl.registerLazySingleton<FaceAuthLocalDataSource>(
    () => FaceAuthLocalDataSourceImpl(
      localAuth: sl(),
      secureStorage: sl(),
    ),
  );

  sl.registerLazySingleton<FaceAuthHttpDataSource>(
    () => FaceAuthHttpDataSource(
      dio: sl(),
      baseUrl: dotenv.env['BACKEND_API_URL'] ?? 'http://localhost:8080',
    ),
  );

  // Face Authentication - Repository
  sl.registerLazySingleton<FaceAuthRepository>(
    () => FaceAuthRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Face Authentication - Use cases
  sl.registerLazySingleton(() => AuthenticateWithFace(sl()));
  sl.registerLazySingleton(() => EnrollFaceBiometric(sl()));

  // Authentication - Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthHttpDataSource(client: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthSecureStorageDataSource(storage: sl()),
  );

  // Authentication - Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Authentication - Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => ForgotPassword(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));

  // Authentication - Provider
  sl.registerFactory(
    () => AuthProvider(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
      authRepository: sl(),
    ),
  );
}
