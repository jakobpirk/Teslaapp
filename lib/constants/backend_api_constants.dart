class BackendApiConstants {
  // Change this to your Laravel backend URL
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Pricing Endpoints
  static const String pricing = '/pricing';
  static const String pricingCurrent = '/pricing/current';
  static const String pricingTodayTomorrow = '/pricing/today-tomorrow';
  static const String pricingAverage = '/pricing/average';

  // Charging Recommendation Endpoints
  static const String chargingRecommendations = '/charging-recommendations';

  static String chargingRecommendationGenerate(String vehicleId) =>
      '/charging-recommendations/vehicle/$vehicleId/generate';

  static String chargingRecommendationLatest(String vehicleId) =>
      '/charging-recommendations/vehicle/$vehicleId/latest';

  static String chargingRecommendationsByVehicle(String vehicleId) =>
      '/charging-recommendations/vehicle/$vehicleId';

  static String chargingRecommendationById(String id) =>
      '/charging-recommendations/$id';

  static String chargingRecommendationMarkExecuted(String id) =>
      '/charging-recommendations/$id/executed';

  static String chargingRecommendationUpdateStatus(String id) =>
      '/charging-recommendations/$id/status';

  // Charging Sessions Endpoints
  static const String chargingSessions = '/charging-sessions';

  static String chargingSessionsByVehicle(String vehicleId) =>
      '/charging-sessions/vehicle/$vehicleId';
}
