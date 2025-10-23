class ApiConstants {
  static const String baseUrl = 'https://api.tessie.com';

  // State Endpoints
  static const String state = '/state';
  static const String battery = '/battery';

  // Vehicle Control
  static const String wake = '/wake';
  static const String lock = '/lock';
  static const String unlock = '/unlock';

  // Climate Control
  static const String startClimate = '/start_climate';
  static const String stopClimate = '/stop_climate';
  static const String setTemperature = '/set_temperature';
  static const String startDefrost = '/start_defrost';
  static const String stopDefrost = '/stop_defrost';
  static const String startSeatHeating = '/start_seat_heating';
  static const String startSeatCooling = '/start_seat_cooling';
  static const String startSteeringWheelHeater = '/start_steering_wheel_heater';
  static const String stopSteeringWheelHeater = '/stop_steering_wheel_heater';

  // Charging
  static const String startCharging = '/start_charging';
  static const String stopCharging = '/stop_charging';
  static const String setChargeLimit = '/set_charge_limit';

  // Vehicle Actions
  static const String flash = '/flash';
  static const String honk = '/honk';
  static const String enableSentryMode = '/enable_sentry_mode';
  static const String disableSentryMode = '/disable_sentry_mode';
  static const String openFrontTrunk = '/open_front_trunk';
  static const String openRearTrunk = '/open_rear_trunk';

  // Windows & Doors
  static const String ventWindows = '/vent_windows';
  static const String closeWindows = '/close_windows';
}
