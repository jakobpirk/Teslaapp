<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChargingSessionController;
use App\Http\Controllers\Api\FaceAuthController;
use App\Http\Controllers\Api\PricingHistoryController;
use App\Http\Controllers\Api\ChargingRecommendationController;
use App\Http\Controllers\VehicleController;
use App\Http\Controllers\ElectricityProviderController;
use App\Http\Controllers\UserSettingsController;
use App\Http\Controllers\AuraController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // Health check
    Route::get('/health', function () {
        return response()->json([
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    // Authentication Routes (Public)
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/verify-reset-code', [AuthController::class, 'verifyResetCode']);
        Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    });

    // Protected Authentication Routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
    });

    // Charging Sessions Routes (Protected)
    Route::middleware('auth:sanctum')->prefix('charging-sessions')->group(function () {
        Route::get('/', [ChargingSessionController::class, 'index']);
        Route::post('/', [ChargingSessionController::class, 'store']);
        Route::get('/{id}', [ChargingSessionController::class, 'show']);
        Route::put('/{id}', [ChargingSessionController::class, 'update']);
        Route::delete('/{id}', [ChargingSessionController::class, 'destroy']);
        Route::get('/vehicle/{vehicleId}', [ChargingSessionController::class, 'getByVehicle']);
        Route::get('/vehicle/{vehicleId}/recent', [ChargingSessionController::class, 'getMostRecent']);
        Route::get('/vehicle/{vehicleId}/date-range', [ChargingSessionController::class, 'getByDateRange']);
    });

    // Face Authentication Routes
    Route::prefix('face-auth')->group(function () {
        Route::post('/enrollments', [FaceAuthController::class, 'registerEnrollment']);
        Route::get('/enrollments/{userId}', [FaceAuthController::class, 'getEnrollment']);
        Route::delete('/enrollments/{userId}', [FaceAuthController::class, 'deleteEnrollment']);
        Route::post('/verify', [FaceAuthController::class, 'verifyAuthentication']);
        Route::post('/sessions/verify', [FaceAuthController::class, 'verifySessionToken']);
        Route::post('/sessions/invalidate', [FaceAuthController::class, 'invalidateSession']);
    });

    // Pricing History Routes
    Route::prefix('pricing')->group(function () {
        Route::get('/', [PricingHistoryController::class, 'index']);
        Route::get('/current', [PricingHistoryController::class, 'current']);
        Route::get('/today-tomorrow', [PricingHistoryController::class, 'todayAndTomorrow']);
        Route::get('/average', [PricingHistoryController::class, 'average']);
    });

    // Charging Recommendation Routes (Protected)
    Route::middleware('auth:sanctum')->prefix('charging-recommendations')->group(function () {
        Route::post('/vehicle/{vehicleId}/generate', [ChargingRecommendationController::class, 'generate']);
        Route::get('/vehicle/{vehicleId}/latest', [ChargingRecommendationController::class, 'latest']);
        Route::get('/vehicle/{vehicleId}', [ChargingRecommendationController::class, 'index']);
        Route::get('/{id}', [ChargingRecommendationController::class, 'show']);
        Route::post('/{id}/executed', [ChargingRecommendationController::class, 'markExecuted']);
        Route::patch('/{id}/status', [ChargingRecommendationController::class, 'updateStatus']);
    });

    // Vehicle Routes (Protected)
    Route::middleware('auth:sanctum')->prefix('vehicles')->group(function () {
        Route::get('/', [VehicleController::class, 'index']);
        Route::get('/active', [VehicleController::class, 'active']);
        Route::post('/', [VehicleController::class, 'store']);
        Route::get('/{id}', [VehicleController::class, 'show']);
        Route::put('/{id}', [VehicleController::class, 'update']);
        Route::delete('/{id}', [VehicleController::class, 'destroy']);
        Route::delete('/{id}/force', [VehicleController::class, 'forceDestroy']);
        Route::get('/{id}/statistics', [VehicleController::class, 'statistics']);
        Route::get('/{id}/charging-settings', [VehicleController::class, 'getChargingSettings']);
        Route::put('/{id}/charging-settings', [VehicleController::class, 'updateChargingSettings']);
    });

    // Electricity Provider Routes (Public for listing, some endpoints protected)
    Route::prefix('electricity-providers')->group(function () {
        Route::get('/', [ElectricityProviderController::class, 'index']);
        Route::get('/{id}', [ElectricityProviderController::class, 'show']);
        Route::get('/{id}/pricing/current', [ElectricityProviderController::class, 'getCurrentPricing']);
        Route::get('/{id}/pricing/forecast', [ElectricityProviderController::class, 'getPricingForecast']);

        // Protected routes for updating pricing
        Route::middleware('auth:sanctum')->group(function () {
            Route::post('/{id}/pricing/update', [ElectricityProviderController::class, 'updatePricing']);
            Route::post('/{id}/pricing/forecast/update', [ElectricityProviderController::class, 'updateForecast']);
        });
    });

    // User Settings Routes (Protected)
    Route::middleware('auth:sanctum')->prefix('user')->group(function () {
        Route::get('/settings', [UserSettingsController::class, 'index']);
        Route::get('/profile', [UserSettingsController::class, 'profile']);
        Route::post('/settings/tessie-api-key', [UserSettingsController::class, 'updateTessieApiKey']);
        Route::delete('/settings/tessie-api-key', [UserSettingsController::class, 'removeTessieApiKey']);
        Route::post('/settings/electricity-provider', [UserSettingsController::class, 'updateElectricityProvider']);
        Route::post('/settings/pricing-region', [UserSettingsController::class, 'updatePricingRegion']);
        Route::delete('/settings/pricing-region', [UserSettingsController::class, 'removePricingRegion']);
        Route::post('/settings/auto-charging', [UserSettingsController::class, 'updateAutoCharging']);
        Route::post('/settings/low-battery-protection', [UserSettingsController::class, 'updateLowBatteryProtection']);
    });

    // Aura Electricity Pricing Routes
    Route::prefix('aura')->group(function () {
        // Public endpoint for Firebase scheduled task
        Route::post('/fetch-prices', [AuraController::class, 'fetchPrices']);

        // Public endpoints for getting pricing data
        Route::get('/pricing', [AuraController::class, 'getPricing']);
        Route::get('/tomorrow/availability', [AuraController::class, 'checkTomorrowAvailability']);
    });
});
